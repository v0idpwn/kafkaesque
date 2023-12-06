defmodule Kafkaesque.Clients.BrodClient do
  @moduledoc """
  Basic client implementation using brod

  Produces synchronously, and automatically starts all the required producers.

  Required options:
  - `:client_id`: An atom which will be used as the client name
  - `:brokers`: A list of {address, port} tuples for kafka brokers. Addresses
  should be charlists.

  Also accepts the same options as `:brod.start_client/3`
  """

  require Logger

  @behaviour Kafkaesque.Client

  @default_opts [reconnect_cool_down_seconds: 2, auto_start_producers: true]

  @impl Kafkaesque.Client
  def start_link(opts) do
    {client_id, opts} = Keyword.pop!(opts, :client_id)
    {brokers, opts} = Keyword.pop!(opts, :brokers)

    opts = Keyword.merge(@default_opts, opts)

    :ok = :brod.start_client(brokers, client_id, opts)
    {:ok, task_supervisor} = Task.Supervisor.start_link()

    {:ok, %{brod_client_id: client_id, task_supervisor: task_supervisor}}
  end

  @impl Kafkaesque.Client
  def publish(%{brod_client_id: client_id, task_supervisor: task_supervisor}, messages) do
    # We pre-process the message bodies to avoid copying unecessary data to the task
    message_batches = Enum.group_by(messages, &{&1.partition, &1.topic}, & &1.body)

    task_results =
      task_supervisor
      |> Task.Supervisor.async_stream_nolink(message_batches, fn {{partition, topic}, values} ->
        case :brod.produce_sync(client_id, topic, partition, "", values) do
          :ok ->
            {{partition, topic}, :success}

          error ->
            log_error(topic, partition, error)
            {{partition, topic}, :error}
        end
      end)
      |> Map.new(fn {:ok, task_result} -> task_result end)

    result =
      Enum.group_by(messages, fn m ->
        Map.fetch!(task_results, {m.partition, m.topic})
      end)
      |> Map.put_new(:success, [])
      |> Map.put_new(:error, [])

    {:ok, result}
  end

  defp log_error(topic, partition, error) do
    ("#{inspect(__MODULE__)} failure publishing message batch to topic " <>
       "#{inspect(topic)} partition #{inspect(partition)} with error " <>
       inspect(error))
    |> Logger.warning()
  end
end
