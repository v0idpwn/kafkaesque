defmodule KafkaesqueTest do
  use Kafkaesque.Case

  alias Kafkaesque.Test.Repo

  describe "publish/3" do
    @tag :integration
    test "inserts valid messages" do
      {:ok, %Kafkaesque.Message{}} = Kafkaesque.publish(Repo, "test_topic", %{})
    end

    test "errors for invalid messages" do
      invalid_topic = 1
      invalid_body = {1, 2}

      assert {:error, %Ecto.Changeset{}} = Kafkaesque.publish(Repo, invalid_topic, invalid_body)
    end
  end
end
