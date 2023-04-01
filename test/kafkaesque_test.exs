defmodule KafkaesqueTest do
  use Kafkaesque.Case, async: false

  alias Kafkaesque.Test.Repo

  describe "publish/4" do
    test "inserts valid messages" do
      {:ok, %Kafkaesque.Message{}} = Kafkaesque.publish(Repo, "test_topic", 0, "content")
    end

    test "errors for invalid messages" do
      invalid_topic = 1
      invalid_body = {1, 2}
      invalid_partition = "notanumber"

      assert {:error, %Ecto.Changeset{}} =
               Kafkaesque.publish(Repo, invalid_topic, invalid_partition, invalid_body)
    end
  end
end
