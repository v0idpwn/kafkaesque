defmodule Kafkaesque.QueryTest do
  use Kafkaesque.Case, async: false

  alias Kafkaesque.Message
  alias Kafkaesque.Query

  setup do
    Repo.delete_all(Message)
    :ok
  end

  describe "pending_messages/2" do
    test "returns messages of topics/partitions that don't have messages in the publishing state" do
      Repo.insert(%Message{topic: "foobar", partition: 0})
      Repo.insert(%Message{topic: "foobar", partition: 0})
      Repo.insert(%Message{topic: "foobaz", partition: 0, state: :publishing})
      Repo.insert(%Message{topic: "foobaz", partition: 1})

      assert {:ok,
              {3,
               [
                 %Message{topic: "foobar"},
                 %Message{topic: "foobar"},
                 %Message{topic: "foobaz", partition: 1}
               ]}} = Query.pending_messages(Repo, 10)

      assert {:ok, {0, []}} = Query.pending_messages(Repo, 10)
    end

    test "sets the returned messages as publishing" do
      Repo.insert(%Message{topic: "foobar", partition: 0})
      Repo.insert(%Message{topic: "foobar", partition: 0})
      Repo.insert(%Message{topic: "foobaz", partition: 0})

      assert {:ok, {3, messages}} = Query.pending_messages(Repo, 10)
      assert Enum.all?(messages, &(&1.state == :publishing))
    end
  end

  describe "update_success_batch/2" do
    test "updates the state of the messages" do
      {:ok, %{id: id}} = Repo.insert(%Message{topic: "foobar", partition: 0})
      assert {1, _} = Query.update_success_batch(Repo, [id])
      assert %{state: :published} = Repo.get(Message, id)
    end
  end

  describe "update_failed_batch/2" do
    test "updates the state of the messages" do
      {:ok, %{id: id}} = Repo.insert(%Message{topic: "foobar", partition: 0})
      assert {1, _} = Query.update_failed_batch(Repo, [id])
      assert %{state: :failed} = Repo.get(Message, id)
    end
  end
end
