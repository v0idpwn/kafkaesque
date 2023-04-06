defmodule Kafkaesque.Acknowledger do
  @moduledoc """
  Stage that updates in the database the messages that were published in Kafka

  Takes 3 options:
  - `:publisher_pid`: pid of the stage that will publish the messages.
  - `:repo`: the repo to execute the queries on.
  - `:query_opts`: A list of options sent to Repo calls.
  """

  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl GenStage
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    query_opts = Keyword.fetch!(opts, :query_opts)
    publisher_pid = Keyword.fetch!(opts, :publisher_pid)

    {
      :consumer,
      %{repo: repo, query_opts: query_opts},
      [subscribe_to: [publisher_pid]]
    }
  end

  def shutdown(pid, timeout) do
    try do
      GenStage.stop(pid, :shutdown, timeout)
    catch
      _, _ -> :ok
    end
  end

  # TODO: possibly perform additional batching for performance in cases where
  # workload is mostly composed by messages from different queues (thus coming
  # in different batches)
  @impl GenStage
  def handle_events(events, _from, state) do
    :telemetry.span([:kafkaesque, :acknowledge], %{repo: state.repo}, fn ->
      {Enum.each(events, &handle_event(&1, state)), %{}}
    end)

    {:noreply, [], state}
  end

  # empty batches
  defp handle_event({_, []}, state), do: {:noreply, [], state}

  defp handle_event({:success_batch, items}, state) do
    Kafkaesque.Query.update_success_batch(state.repo, items, state.query_opts)
  end

  defp handle_event({:failure_batch, items}, state) do
    Kafkaesque.Query.update_failed_batch(state.repo, items, state.query_opts)
  end
end
