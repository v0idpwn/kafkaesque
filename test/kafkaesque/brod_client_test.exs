defmodule Kafkaesque.KafkaClients.BrodClientTest do
  use Kafkaesque.Case, async: false

  alias Kafkaesque.KafkaClients.BrodClient

  setup_all do
    topic_configs = [
      %{
        configs: [
          %{
            name: "cleanup.policy",
            value: "compact"
          },
          %{
            name: "confluent.value.schema.validation",
            value: false
          }
        ],
        num_partitions: 1,
        replication_factor: 1,
        assignments: [],
        name: "integration_test_topic"
      },
      %{
        configs: [
          %{
            name: "cleanup.policy",
            value: "compact"
          },
          %{
            name: "confluent.value.schema.validation",
            value: true
          }
        ],
        num_partitions: 1,
        replication_factor: 1,
        assignments: [],
        name: "integration_test_topic_2"
      }
    ]

    _ = :brod.create_topics([{"localhost", 9092}], topic_configs, %{timeout: 15_000})

    :ok
  end

  # required a running kafka instance
  @tag :integration
  test "starts and publishes messages" do
    assert {:ok, client} =
             BrodClient.start_link(
               client_id: :my_client,
               brokers: [{"localhost", 9092}]
             )

    # Success case
    message = %Kafkaesque.Message{
      id: 1,
      partition: 0,
      topic: "integration_test_topic",
      body: "test_message"
    }

    assert {:ok, %{success: [%Message{body: "test_message"}]}} =
             BrodClient.publish(client, [message])

    # Failure case
    message = %Kafkaesque.Message{
      id: 1,
      partition: 9,
      topic: "integration_test_topic_2",
      body: "test_message"
    }

    assert {:ok, %{error: [%Message{body: "test_message"}]}} =
             BrodClient.publish(client, [message])
  end
end
