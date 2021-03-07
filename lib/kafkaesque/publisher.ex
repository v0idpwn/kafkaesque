defmodule Kafkaesque.Publisher do
  @moduledoc """
  Publishes polled messages in Kafka
  """

  @default_opts [reconnect_cool_down_seconds: 2]

  def client(opts) do 
    {client_id, opts} = Keyword.pop!(opts, :client_id)
    {address, opts} = Keyword.pop!(opts, :address)
    {port, opts} = Keyword.pop!(opts, :port)

    opts = Keyword.merge(@default_opts, opts)
    
    :ok = :brod.start_client([{address, port}], client_id, opts)

    {:ok, client_id}
  end

  def publish(client, message) do 
    case :brod.produce_sync_offset(client, message.topic, 0, "", Jason.encode!(message.body)) do
      :ok ->
        :ok

      {:error, {:producer_not_found, topic}} ->
        :brod.start_producer(client, topic, [])
        publish(client, message)

      err ->
        err
    end
  end
end
