defmodule Kafkaesque.QueryTest do
  use Kafkaesque.Case

  alias Kafkaesque.Message
  alias Kafkaesque.Query

  describe "pending_messages/2" do
    test "returns first pending message of each topic, doesn't any messages if the topic has messages being published" do
      Repo.delete_all(Message)

      Repo.insert(%Message{topic: "foobar"})
      Repo.insert(%Message{topic: "foobar"})
      Repo.insert(%Message{topic: "foobaz"})

      assert {:ok, [%Message{}, %Message{}]} = Query.pending_messages(Repo, 10)
      assert {:ok, []} = Query.pending_messages(Repo, 10)
    end
  end

  test "sets the returned messages as publishing" do
    import Ecto.Query

    Repo.delete_all(Message)

    Repo.insert(%Message{topic: "foobar"})
    Repo.insert(%Message{topic: "foobar"})
    Repo.insert(%Message{topic: "foobaz"})

    assert {:ok, [%Message{}, %Message{}]} = Query.pending_messages(Repo, 10)

    assert [%{state: :publishing}, %{state: :pending}, %{state: :publishing}] =
             Message
             |> order_by([:id])
             |> Repo.all()
  end
end
