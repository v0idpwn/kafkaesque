defmodule Kafkaesque do
  @moduledoc """
  This module provides a message publishing API through `Kafkaesque.publish/3`.

  It also allows you to `use` it and have a streamlined publishing function,
  possibly providing encodin function:


      defmodule MyApp.Kafka do
        use Kafkaesque, repo: MyApp.Repo

        # Optional, defaults to `body`
        def encode(body) do
          Jason.encode!(body)
        end

        def partition(_topic, %MyMessage{id: id}) do
          id
        end
      end

      MyApp.Kafka.publish("my_topic", %{hello: :kafka})

  `encode/1` should return a string, and defaults to the identity function.

  `partition/2` should return an integer, and defaults to 0. It will be used
  as the partition for the message.
  """

  use GenServer

  alias Kafkaesque.Message

  @doc """
  Publishes a message in the outbox.

  While you can use this function, this is not the recommended approach to
  use the library. See the documentation of the `Kafkaesque` module for more
  information.
  """
  @spec publish(Ecto.Repo.t(), String.t(), term(), String.t()) ::
          {:ok, Message.t()} | {:error, atom()}
  def publish(repo, topic, partition, payload) do
    message = Message.new(topic, partition, payload)
    repo.insert(message)
  end

  @doc """
  Starts a Kafkaesque instance. Accepts the following opts:
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    {:ok, producer_pid} = Kafkaesque.Producer.start_link(opts)

    {:ok, publisher_pid} =
      opts
      |> Keyword.put(:producer_pid, producer_pid)
      |> Kafkaesque.Publisher.start_link()

    {:ok, acknowledger_pid} =
      opts
      |> Keyword.put(:publisher_pid, publisher_pid)
      |> Kafkaesque.Acknowledger.start_link()

    # {:ok, stager_pid} = Kafkaesque.Stager.start_link(opts)

    {:ok, %{producer: producer_pid, publisher: publisher_pid, acknowledger: acknowledger_pid}}
  end

  defmacro __using__(opts) do
    {repo, _opts} = Keyword.pop!(opts, :repo)

    quote do
      def start_link(opts) do
        Kafkaesque.start_link(opts)
      end

      @spec publish(String.t(), term()) :: {:ok, Kafkaesque.Message.t()} | {:error, atom()}
      def publish(topic, body) do
        payload = encode(message)
        Kafkaesque.publish(unquote(repo), topic, payload)
      end

      @spec encode(term()) :: String.t()
      def encode(body) do
        body
      end

      @spec partition(String.t(), term()) :: integer()
      def partition(_topic, _body) do
        0
      end

      defoverridable encode: 1, partition: 2
    end
  end
end
