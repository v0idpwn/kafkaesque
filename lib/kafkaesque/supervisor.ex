defmodule Kafkaesque.Supervisor do
  @moduledoc """
  Supervisor for Kafkaesque
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      {Kafkaesque.Rescuer, opts},
      {Kafkaesque.GarbageCollector, opts},
      {Kafkaesque.Pipeline, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
