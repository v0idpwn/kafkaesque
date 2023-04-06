defmodule Kafkaesque.Producer do
  @moduledoc """
  Queries the database for messages to be published

  Takes 2 options on startup:
  - `:producer_max_backoff_ms`: maximum time in milliseconds that the producer will
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
    max_backoff = Keyword.fetch!(opts, :producer_max_backoff_ms)

    {:producer,
     %{
       repo: repo,
       demand: 0,
       producing?: true,
       max_backoff: max_backoff,
       backoff: @starting_backoff
     }}
  end

  @impl GenStage
  def handle_demand(new_demand, state) do
    produce_messages(new_demand, state)
  end

  @impl GenStage
  def handle_info(:tick, state) do
    produce_messages(0, state)
  end

  @impl GenStage
  def handle_info(:stop_producing, state) do
    GenStage.demand(self(), :accumulate)
    {:noreply, [], %{state | producing?: false}}
  end

  def stop_producing(pid) do
    send(pid, :stop_producing)
    :ok
  end

  def shutdown(pid, timeout) do
    try do
      GenStage.stop(pid, :shutdown, timeout)
    catch
      _, _ -> :ok
    end
  end

  defp produce_messages(new_demand, state) do
    demand = new_demand + state.demand

    if state.producing? do
      :telemetry.span([:kafkaesque, :produce], %{repo: state.repo, demand: demand}, fn ->
        response =
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

        {response, %{}}
      end)
    else
      {:noreply, [], state}
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
