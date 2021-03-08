defmodule Kafkaesque.MessageTest do
  use Kafkaesque.Case

  alias Kafkaesque.Message

  describe "new/2" do
    test "returns a changeset for a new message" do
      topic = "sample"
      body = %{"key" => 1}

      assert %Ecto.Changeset{errors: [], changes: %{topic: ^topic, body: ^body}} =
               Message.new(topic, body)
    end

    test "returns invalid changeset for invalid input" do
      topic = 1
      body = {1, 2}
      assert %Ecto.Changeset{errors: [topic: _, body: _]} = Message.new(topic, body)
    end
  end

  describe "set_published/2" do
    test "changes offset and state" do
      offset = 1

      assert %Ecto.Changeset{changes: %{offset: ^offset, state: :published}} =
               Message.set_published(%Message{}, offset)
    end
  end

  describe "set_failed/1" do
    test "changes state to failed" do
      assert %Ecto.Changeset{changes: %{state: :failed}} = Message.set_failed(%Message{})
    end
  end
end
