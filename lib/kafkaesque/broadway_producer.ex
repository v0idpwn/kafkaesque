defmodule Kafkaesque.Producer do
  @moduledoc """
  Queries the database for messages to be published

  Takes 2 options on startup:
  - `:max_producer_backoff`: maximum time in milliseconds that the producer will
  take between database reads. Notice that this is edge-case scenario and should
  only happen when a) there are database issues or b) there are no new messages
  in the table for long
  - `:repo`: the repo the producer will query on
  """

  use GenStage

  require Logger

  alias Kafkaesque.Query

  @starting_backoff 50

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    max_backoff = Keyword.get(opts, :max_backoff, 500)

    {:producer, %{repo: repo, demand: 0, max_backoff: max_backoff, backoff: @starting_backoff}}
  end

  @impl GenStage
  def handle_demand(new_demand, state) do
    produce_messages(new_demand, state)
  end

  @impl GenStage
  def handle_info(:tick, state) do
    produce_messages(0, state)
  end

  defp produce_messages(new_demand, state) do
    demand = new_demand + state.demand

    case Query.pending_messages(state.repo, demand) do
      {:ok, {count, messages}} ->
        remaining_demand = demand - count

        if remaining_demand == 0 do
          {:noreply, messages, %{state | demand: remaining_demand}}
        else
          backoff = next_backoff(state.backoff, state.max_backoff, count)
          send_tick_after_backoff(backoff)
          {:noreply, messages, %{state | backoff: backoff, demand: remaining_demand}}
        end

      error ->
        backoff = next_backoff(state.backoff, state.max_backoff, 0)

        Logger.warn(
          "#{inspect(__MODULE__)}.produce_messages/2 failed with #{inspect(error)}, retrying in #{backoff}ms"
        )

        send_tick_after_backoff(backoff)
        {:noreply, [], %{state | backoff: backoff, demand: demand}}
    end
  end

  defp send_tick_after_backoff(backoff) do
    Process.send_after(self(), :tick, backoff)
  end

  defp next_backoff(current, max, 0) do
    min(current * 2, max)
  end

  defp next_backoff(_current, _max, _) do
    @starting_backoff
  end
end
