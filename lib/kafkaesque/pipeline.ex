defmodule Kafkaesque.Pipeline do
  @moduledoc """
  This process just initializes the stages, linked to it. If one stage die,
  all stages die.

  It also takes care of termination of the stages.
  """

  use GenServer

  require Logger

  alias Kafkaesque.Acknowledger
  alias Kafkaesque.Producer
  alias Kafkaesque.Publisher

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Process.flag(:trap_exit, true)

    {:ok, producer_pid} = Producer.start_link(opts)

    {:ok, publisher_pid} =
      opts
      |> Keyword.put(:producer_pid, producer_pid)
      |> Publisher.start_link()

    {:ok, acknowledger_pid} =
      opts
      |> Keyword.put(:publisher_pid, publisher_pid)
      |> Acknowledger.start_link()

    {:ok,
     %{
       producer: producer_pid,
       publisher: publisher_pid,
       acknowledger: acknowledger_pid
     }}
  end

  def terminate(:shutdown, state) do
    # Drain
    :ok = Producer.stop_producing(state.producer)

    # Shutdown
    :ok = Producer.shutdown(state.producer, 5000)
    :ok = Publisher.shutdown(state.publisher, 5000)
    :ok = Acknowledger.shutdown(state.acknowledger, 5000)
  end

  def terminate(reason, _state) do
    Logger.warn("#{inspect(__MODULE__)} terminating with reason #{inspect(reason)}")
  end
end
