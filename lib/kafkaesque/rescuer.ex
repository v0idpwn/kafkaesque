defmodule Kafkaesque.Rescuer do
  @moduledoc """
  Rescues messages stuck in publishing state

  If the shutdown wasn't graceful or there are errors, there is the possibility
  that messages get lost in the `:publishing` state, which would stop the
  publishing for a topic + partition combination. This process rescues the
  stuck messages periodically.


  Takes 3 options on startup:
  - `:repo`: the repo to perform garbage collection on
  - `:query_opts`: A list of options sent to Repo calls.
  - `:rescuer_interval_ms`: the interval between garbage collection
  runs. Notice that it always runs on tstartup.
  - `rescuer_limit_ms`: the time limit for records to be in the publishing
  state. Notice that they may stay longer in this state due to the interval.
  """

  use GenServer

  alias Kafkaesque.Query

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    repo = Keyword.fetch!(opts, :repo)
    query_opts = Keyword.fetch!(opts, :query_opts)
    interval_ms = Keyword.fetch!(opts, :rescuer_interval_ms)
    limit_ms = Keyword.fetch!(opts, :rescuer_limit_ms)

    {:ok, %{repo: repo, query_opts: query_opts, interval_ms: interval_ms, limit_ms: limit_ms},
     {:continue, :rescue}}
  end

  @impl GenServer
  def handle_continue(:rescue, state) do
    :telemetry.span([:kafkaesque, :rescue], %{repo: state.repo}, fn ->
      {Query.rescue_publishing(state.repo, state.limit_ms, state.query_opts), %{}}
    end)

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
