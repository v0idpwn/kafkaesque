defmodule Kafkaesque.Test.Helpers do
  def create_topics() do
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

    case :brod.create_topics([{"localhost", 9092}], topic_configs, %{timeout: 15_000}) do
      :ok -> :ok
      {:error, :topic_already_exists} -> :ok
      resp -> raise "Couldn't create topics - :brod.create_topics/3 returned #{inspect(resp)}"
    end
  end
end
