defmodule KafkaesqueTest do
  use Kafkaesque.Case, async: false

  alias Kafkaesque.Test.Repo

  describe "publish/4" do
    test "inserts valid messages" do
      {:ok,
       %Kafkaesque.Message{
         key: "test_key",
         body: "content",
         state: :pending,
         topic: "test_topic"
       }} =
        Kafkaesque.publish(Repo, "test_topic", 0, "test_key", "content")

      {:ok,
       %Kafkaesque.Message{
         key: "test_key",
         body: %{test: "content"},
         state: :pending,
         topic: "test_topic"
       }} =
        Kafkaesque.publish(Repo, "test_topic", 0, "test_key", %{test: "content"})
    end

    test "errors for invalid messages" do
      invalid_topic = 1
      invalid_key = 2
      invalid_partition = "notanumber"

      assert {:error, %Ecto.Changeset{errors: [topic: _, partition: _, key: _]}} =
               Kafkaesque.publish(
                 Repo,
                 invalid_topic,
                 invalid_partition,
                 invalid_key,
                 %{}
               )
    end
  end
end
