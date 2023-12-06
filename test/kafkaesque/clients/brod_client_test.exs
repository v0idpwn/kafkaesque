defmodule Kafkaesque.Clients.BrodClientTest do
  use Kafkaesque.Case, async: false

  alias Kafkaesque.Clients.BrodClient

  setup_all do
    Kafkaesque.Test.Helpers.create_topics()
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
      body: "test_message"
    }

    assert {:ok, %{error: [%Message{body: "test_message"}]}} =
             BrodClient.publish(client, [message])
  end
end
