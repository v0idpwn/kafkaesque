defmodule Kafkaesque.GarbageCollector do
  @moduledoc """
  Garbage collects messages that were already published
  """

  use GenServer

  alias Kafkaesque.Query

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    interval_ms = Keyword.get(opts, :garbage_collector_interval_ms, :timer.seconds(15))
    limit_ms = Keyword.get(opts, :garbage_collector_limit_ms, :timer.hours(72))

    {:ok, %{repo: repo, interval_ms: interval_ms, limit_ms: limit_ms}, {:continue, :rescue}}
  end

  @impl GenServer
  def handle_continue(:garbage_collect, state) do
    Query.garbage_collect(state.repo, state.limit_ms)

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
