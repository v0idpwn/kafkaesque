defmodule Kafkaesque do
  @moduledoc """
  This module provides the main APIs for Kafkaesque

  ### Introduction

  Kafkaesque is an outbox library built for PostgreSQL and designed, primarily,
  for Kafka, though usage with other software is possible and encouraged.

  - Transactional safety for messages: if they were created, they **will** be
  eventually published. They're only created if the transaction commits.
  - Ordering: messages are published sequentially for topic/partition combinations
  - Shutdown safety: has graceful shutdown and rescue for cases where it doesn't
  happen.
  - Observability: all operations publish telemetry events.
  - Garbage collection: outbox table is periodically cleaned.
  - Multi-node safe: safety powered by PostgreSQL.

  For a comprehensive installation guide, check the [Getting started]("getting-started.md")
  guide.

  ![Basic diagram](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/v0idpwn/kafkaesque/master/diagrams/basic.iuml)

  #### Note

  For most cases, this module shouldn't be called directly. Instead, you want to
  `use` it to define an outbox for your application, and call the outbox, as you
  do with Ecto repos.
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
  Starts a Kafkaesque instance.

  Accepts the following opts:

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
  @spec start_link(Keyword.t()) :: {:ok, pid()}
  def start_link(opts) do
    opts = Keyword.validate!(opts, [:repo] ++ @default_opts)
    Kafkaesque.Supervisor.start_link(opts)
  end

  @doc """
  Child spec for a Kafkaesque instance
  """
  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
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

      @spec start_link(Keyword.t()) :: {:ok, pid}
      def start_link(opts) do
        opts = Keyword.merge(unquote(opts), opts)
        Kafkaesque.start_link(opts)
      end

      @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
      def child_spec(opts) do
        opts = Keyword.merge(unquote(opts), opts)
        Kafkaesque.child_spec(opts)
      end

      defoverridable encode: 1, partition: 2
    end
  end
end
