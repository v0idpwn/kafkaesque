defmodule Kafkaesque.CompileHooks do
  @moduledoc false

  # We need to raise a compile error if partition/2 is defined due to a breaking
  # change: outbox modules are now expected to implement partition/3, not partition/2
  #
  # This way we turn the breaking change into a compile error instead of runtime
  # misbehaviour
  def on_def(_env, :def, :partition, args, _guards, _body) do
    if Enum.count(args) == 3 do
      :ok
    else
      raise "partition function is expected to have 3 arguments"
    end
  end

  def on_def(_env, _kind, _name, _args, _guards, _body) do
    :ok
  end
end
