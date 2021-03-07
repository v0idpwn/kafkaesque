defmodule Kafkaesque do
  @moduledoc """
  Documentation for `Kafkaesque`.
  """

  alias Kafkaesque.Message

  @doc """
  Publishes a message in the outbox
  """
  @spec publish(Ecto.Repo.t(), String.t(), map()) :: {:ok, Message.t()} | {:error, atom()}
  def publish(repo, topic, payload) do
    topic
    |> Message.new(payload)
    |> repo.insert()
  end

  defmacro __using__(opts) do
    {repo, _opts} = Keyword.pop!(opts, :repo)

    quote do
      def publish(topic, payload) do
        Kafkaesque.publish(unquote(repo), topic, payload)
      end
    end
  end
end
