defmodule Kafkaesque.QueryTest do
  use Kafkaesque.Case

  alias Kafkaesque.Message
  alias Kafkaesque.Query

  setup do
    Repo.delete_all(Message)

    :ok
  end

  describe "pending_messages/2" do
    test "returns messages of topics+partitions that don't have messages in the publishing state" do
      Repo.insert(%Message{topic: "foobar", partition: 0})
      Repo.insert(%Message{topic: "foobar", partition: 0})
      Repo.insert(%Message{topic: "foobaz", partition: 0, state: :publishing})

      assert {:ok, {2, [%Message{}, %Message{}]}} = Query.pending_messages(Repo, 10)
      assert {:ok, {0, []}} = Query.pending_messages(Repo, 10)
    end
  end

  test "sets the returned messages as publishing" do
    Repo.insert(%Message{topic: "foobar"})
    Repo.insert(%Message{topic: "foobar"})
    Repo.insert(%Message{topic: "foobaz"})

    assert {:ok, {3, messages}} = Query.pending_messages(Repo, 10)
    assert Enum.all?(messages, &(&1.state == :publishing))
  end
end
