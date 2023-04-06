defmodule Kafkaesque.Terminator do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:ok, []}
  end
end
