defmodule Kafkaesque.Rescuer do
  @moduledoc """
  Rescues messages stuck in publishing state

  If the shutdown wasn't graceful or there are errors, there is the possibility
  that messages get lost in the `:publishing` state, which would stop the
  publishing for a topic + partition combination. This process rescues the
  stuck messages periodically.
  """

  use GenServer

  alias Kafkaesque.Query

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    interval_ms = Keyword.get(opts, :rescuer_interval_ms, :timer.seconds(5))
    limit_ms = Keyword.get(opts, :rescuer_limit_ms, :timer.seconds(15))

    {:ok, %{repo: repo, interval_ms: interval_ms, limit_ms: limit_ms}, {:continue, :rescue}}
  end

  @impl GenServer
  def handle_continue(:rescue, state) do
    Query.rescue_publishing(state.repo, state.limit_ms)

    {:noreply, state, {:continue, :schedule_next}}
  end

  def handle_continue(:schedule_next, state) do
    :erlang.send_after(state.interval_ms, self(), :rescue)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:rescue, state) do
    {:noreply, state, {:continue, :rescue}}
  end
end
