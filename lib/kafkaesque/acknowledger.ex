defmodule Kafkaesque.Acknowledger do
  @moduledoc """
  Stage that updates in the database the messages that were published in Kafka

  Takes 3 options:
  - `:publisher_pid`: pid of the stage that will publish the messages.
  - `:repo`: the repo to execute the queries on.  - `:client_opts`: A list of options to be passed to the client on startup.
  """

  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    producer_pid = Keyword.fetch!(opts, :publishr_pid)

    {
      :consumer,
      %{repo: repo},
      [subscribe_to: [producer_pid]]
    }
  end

  # TODO: possibly perform additional batching for performance in cases where
  # batches are mostly composed by messages from different queues.
  @impl GenStage
  def handle_events(events, _from, state) do
    Enum.each(events, &handle_event(&1, state))
    {:noreply, [], state}
  end

  # empty batches
  defp handle_event({_, []}, state), do: {:noreply, [], state}

  defp handle_event({:success_batch, items}, state) do
    Kafkaesque.Query.update_success_batch(state.repo, items)
  end

  defp handle_event({:failure_batch, items}, state) do
    Kafkaesque.Query.update_failed_batch(state.repo, items)
  end
end
