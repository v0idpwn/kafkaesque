defmodule Kafkaesque.Client do
  @type client() :: term()
  @callback start_link(Keyword.t()) :: {:ok, client()} | {:error, term()}
  @callback publish(client(), [Kafkaesque.Message.t()]) ::
              {:ok, %{success: [Message.t()], error: [Message.t()]}} | {:error, term()}
end
