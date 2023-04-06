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

  See the documentation for `Kafkaesque.start_link/1` to learn about starting
  Kafkaesque in your application.
  """

  alias Kafkaesque.Message

  @default_opts [
    client: Kafkaesque.Clients.BrodClient,
    client_opts: [],
    producer_max_backoff_ms: 500,
    publisher_min_demand: 190,
    publisher_max_demand: 200,
    rescuer_interval_ms: :timer.seconds(15),
    rescuer_limit_ms: :timer.seconds(15),
    garbage_collector_interval_ms: :timer.seconds(30),
    garbage_collector_limit_ms: :timer.hours(72),
    query_opts: [log: false]
  ]

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

  - `:repo`: the repo where messages will be read from. Usually should be the
  same repo that you're writing to.
  - `:client`: the client to be used by the publisher. Defaults to
  `Kafkaesque.Clients.BrodClient`
  - `:client_opts`: the options to be used by the client. Defaults to `[]`. The
  default client requires options, so this can be considered required for most
  use-cases. Look at the client documentation for more information about the
  client options.
  - `:producer_max_backoff_ms`: maximum time in milliseconds that the producer will
  take between database reads. Notice that this is edge-case scenario and should
  only happen when a) there are database issues or b) there are no new messages
  in the table for long.
  - `:publisher_max_demand`: maximum publisher demand, can be useful for tuning.
  Defaults to 200. See `GenStage` documentation for more info.
  - `:publisher_min_demand`: minimum publisher demand, can be useful for tuning.
  Defaults to 190. See `GenStage` documentation for more info.
  - `:rescuer_interval_ms`: the interval between garbage collection
  runs. Defaults to 15 seconds. Notice that it always runs on tree startup.
  - `rescuer_limit_ms`: the time limit for records to be in the publishing
  state. Defaults to 15 seconds. Notice that they may stay longer in this state
  due to the interval.
  - `:garbage_collector_interval_ms`: the interval between garbage collection
  runs. Defaults to 30 seconds. Notice that it always runs on tree startup.
  - `garbage_colletor_limit_ms`: the time limit for published records to be in
  the table. Defaults to 72 hours.
  - `query_opts`: Options to pass to Ecto queries. Defaults to [log: false]
  """
  def start_link(opts) do
    opts = Keyword.validate!(opts, [:repo] ++ @default_opts)
    Kafkaesque.Supervisor.start_link(opts)
  end

  def child_spec(opts) do
    opts = Keyword.validate!(opts, [:repo] ++ @default_opts)
    Kafkaesque.Supervisor.child_spec(opts)
  end

  defmacro __using__(opts) do
    {repo, _opts} = Keyword.pop!(opts, :repo)

    quote do
      @spec publish(String.t(), term()) :: {:ok, Kafkaesque.Message.t()} | {:error, atom()}
      def publish(topic, body) do
        payload = encode(body)
        partition = partition(topic, body)
        Kafkaesque.publish(unquote(repo), topic, partition, payload)
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
