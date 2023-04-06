defmodule Kafkaesque.Client do
  @moduledoc """
  Behaviour for clients
  """

  alias Kafkaesque.Message

  @type client() :: term()
  @callback start_link(Keyword.t()) :: {:ok, client()} | {:error, term()}
  @callback publish(client(), [Message.t()]) ::
              {:ok, %{success: [Message.t()], error: [Message.t()]}} | {:error, term()}
end
