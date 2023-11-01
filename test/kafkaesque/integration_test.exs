defmodule Kafkaesque.IntegrationTest do
  use Kafkaesque.Case, async: false

  alias Kafkaesque.Test.Repo
  alias Kafkaesque.Message

  import Ecto.Query

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
    :timer.sleep(1000)

    message2 = Repo.reload(message)

    assert message2.state == :published
  end

  test "integration: complete flow including termination" do
    # Hack: since there is no synchronization, we execute this test a few times
    # to have increase its chance to fail if there's a bug
    for _ <- 1..10 do
      Repo.delete_all(Message)

      for _ <- 1..1000 do
        MyApp.Kafka.publish("integration_test_topic", %{hello: :kafka})
      end

      {:ok, main_pid} =
        Kafkaesque.start_link(
          repo: Repo,
          client: Kafkaesque.Clients.BrodClient,
          client_opts: [
            brokers: [{"localhost", 9092}],
            client_id: :integration_2_client
          ]
        )

      # Unlinking so the test process doesn't die with the Kafkaesque process
      Process.unlink(main_pid)

      # Monitoring so we can wait for the process to die
      ref = Process.monitor(main_pid)

      # Giving it some time to start publishing messages
      :timer.sleep(200)

      # Sending shutdown and waiting for it
      Process.exit(main_pid, :shutdown)
      assert_receive {:DOWN, ^ref, :process, ^main_pid, :shutdown}, 5000

      # Due to the termination logic, in case of shutdown no messages are left
      # in publishing state
      assert 0 =
               from(Message)
               |> where([m], m.state == :publishing)
               |> Repo.aggregate(:count)
    end
  end
end
