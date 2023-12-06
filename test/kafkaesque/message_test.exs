defmodule Kafkaesque.MessageTest do
  use Kafkaesque.Case, async: true

  alias Kafkaesque.Message

  describe "new/3" do
    test "returns a changeset for a new message" do
      topic = "sample"
      body = "body"
      partition = 0
      key = "some"

      assert %Ecto.Changeset{
               errors: [],
               changes: %{topic: ^topic, body: ^body, partition: ^partition, key: ^key}
             } = Message.new(topic, partition, key, body)
    end

    test "returns invalid changeset for invalid input" do
      topic = 1
      body = {1, 2}
      key = 2
      partition = "notanumber"

      assert %Ecto.Changeset{errors: [topic: _, partition: _, key: _]} =
               Message.new(topic, partition, key, body)
    end
  end
end
