defmodule Kafkaesque.GarbageCollector do
  @moduledoc """
  Garbage collects messages that were already published

  Takes 3 options on startup:
  - `:repo`: the repo to perform garbage collection on
  - `:garbage_collector_interval_ms`: the interval between garbage collection
  runs. Defaults to 30 seconds. Notice that it always runs on tree startup.
  - `garbage_colletor_limit_ms`: the time limit for published records to be in
  the table. Defaults to 72 hours.
  """

  use GenServer

  alias Kafkaesque.Query

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    interval_ms = Keyword.get(opts, :garbage_collector_interval_ms, :timer.seconds(30))
    limit_ms = Keyword.get(opts, :garbage_collector_limit_ms, :timer.hours(72))

    {:ok, %{repo: repo, interval_ms: interval_ms, limit_ms: limit_ms},
     {:continue, :garbage_collect}}
  end

  @impl GenServer
  def handle_continue(:garbage_collect, state) do
    :telemetry.span([:kafkaesque, :garbage_collect], %{repo: state.repo}, fn ->
      {Query.garbage_collect(state.repo, state.limit_ms), %{}}
    end)

    {:noreply, state, {:continue, :schedule_next}}
  end

  def handle_continue(:schedule_next, state) do
    :erlang.send_after(state.interval_ms, self(), :garbage_collect)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:rescue, state) do
    {:noreply, state, {:continue, :garbage_collect}}
  end
end
