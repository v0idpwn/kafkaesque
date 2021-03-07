defmodule KafkaesqueTest do
  use ExUnit.Case
  doctest Kafkaesque

  test "greets the world" do
    assert Kafkaesque.hello() == :world
  end
end
