defmodule Kafkaesque.PublisherTest do
  use Kafkaesque.Case, async: false

  defmodule StubClient do
    use GenServer
    @behaviour Kafkaesque.Client

    @impl Kafkaesque.Client
    def start_link(opts) do
      test_pid = Keyword.fetch!(opts, :test_pid)
      GenServer.start_link(__MODULE__, test_pid)
    end

    @impl Kafkaesque.Client
    def publish(server, messages) do
      GenServer.call(server, {:publish, messages})
    end

    @impl GenServer
    def init(test_pid) do
      {:ok, %{test_pid: test_pid}}
    end

    @impl GenServer
    def handle_call({:publish, messages}, _from, state) do
      send(state.test_pid, {:publish, messages})
      {:reply, {:ok, %{success: messages, error: []}}, state}
    end
  end

  defmodule StubProducer do
    use GenStage

    def start_link(opts) do
      test_pid = Keyword.fetch!(opts, :test_pid)
      GenStage.start_link(__MODULE__, test_pid)
    end

    def produce(producer_pid, events) do
      GenStage.call(producer_pid, {:produce, events})
    end

    @impl GenStage
    def init(test_pid) do
      {:producer, %{test_pid: test_pid}}
    end

    @impl GenStage
    def handle_call({:produce, events}, _from, state) do
      {:reply, :ok, events, state}
    end

    @impl GenStage
    def handle_demand(demand, state) do
      send(state.test_pid, {:demand, demand})
      {:noreply, [], state}
    end
  end

  defmodule StubConsumer do
    use GenStage

    def start_link(opts) do
      test_pid = Keyword.fetch!(opts, :test_pid)
      publisher_pid = Keyword.fetch!(opts, :publisher_pid)
      GenStage.start_link(__MODULE__, {test_pid, publisher_pid})
    end

    @impl GenStage
    def init({test_pid, publisher_pid}) do
      {:consumer, %{test_pid: test_pid}, subscribe_to: [publisher_pid]}
    end

    @impl GenStage
    def handle_events(events, _from, state) do
      send(state.test_pid, {:consumer_events, events})
      {:noreply, [], state}
    end
  end

  test "calls client to publish messages" do
    {:ok, producer_pid} = StubProducer.start_link(test_pid: self())

    {:ok, publisher_pid} =
      Kafkaesque.Publisher.start_link(
        repo: Kafkaesque.Test.Repo,
        producer_pid: producer_pid,
        client: StubClient,
        client_opts: [test_pid: self()]
      )

    {:ok, _consumer_pid} = StubConsumer.start_link(test_pid: self(), publisher_pid: publisher_pid)

    # We receive demand
    assert_receive {:demand, _}

    # Then we produce some stub messages
    messages = [
      message("topic", 0),
      message("topic", 1),
      message("topic2", 0)
    ]

    :ok = StubProducer.produce(producer_pid, messages)

    # The messages are received by the publisher, and the client is called,
    # meaning we will receive a message
    assert_receive {:publish, _messages}

    # The messages are then forwarded to the consumer, and the stub consumer
    # sends to the test process
    assert_receive {:consumer_events, [{:success_batch, [_, _, _]}, {:failure_batch, []}]}
  end

  defp message(topic, partition) do
    %Kafkaesque.Message{topic: topic, partition: partition}
  end
end
