defmodule Kafkaesque.IntegrationTest do
  use Kafkaesque.Case, async: false

  alias Kafkaesque.Test.Repo
  alias Kafkaesque.Message

  setup do
    Repo.delete_all(Message)
    Kafkaesque.Test.Helpers.create_topics()
  end

  defmodule MyApp.Kafka do
    use Kafkaesque, repo: Repo

    def encode(body) do
      Jason.encode!(body)
    end
  end

  test "integration: publishes messages to kafka" do
    {:ok, _} =
      Kafkaesque.start_link(
        repo: Repo,
        client: Kafkaesque.Clients.BrodClient,
        client_opts: [
          brokers: [{"localhost", 9092}],
          client_id: :integration_client
        ]
      )

    assert {:ok, message} = MyApp.Kafka.publish("integration_test_topic", %{hello: :kafka})
    assert message.topic == "integration_test_topic"
    assert message.partition == 0
    assert message.body == Jason.encode!(%{hello: :kafka})
    assert message.state == :pending

    # Could perform some synchronization to avoid sleeping
    :timer.sleep(500)

    message2 = Repo.reload(message)

    assert message2.state == :published
  end
end
