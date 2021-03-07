defmodule Kafkaesque.Query do
  @moduledoc false

  import Ecto.Query

  alias Kafkaesque.Message

  @doc """
  Returns the first pending message on each available topic up to the demand limit

  Sets those messages to `publishing`.
  """
  @spec pending_messages(Ecto.Repo.t(), pos_integer()) ::
          {:ok, list(Message.t())} | {:error, atom()}
  def pending_messages(repo, demand) do
    publishing_topics = 
      Message
      |> select([m], %{topic: fragment("DISTINCT ON (?) ?", m.topic, m.topic)})
      |> where([m], m.state in [:publishing])
      |> order_by([m], m.topic)

    subset =
      Message
      |> select([m], %{id: fragment("DISTINCT ON (?) ?", m.topic, m.id)})
      |> where([m], m.state not in [:published, :publishing])
      |> where([m], m.topic not in subquery(publishing_topics))
      |> order_by([m], [m.topic, m.id])
      |> limit(^demand)

    updates = [
      set: [
        state: "publishing",
        attempted_at: NaiveDateTime.utc_now(),
        attempted_by: inspect(node())
      ],
      inc: [attempt: 1]
    ]

    repo.transaction(fn ->
      repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE", [])

      Message
      |> where([m], m.id in subquery(subset))
      |> select([m, _], m)
      |> repo.update_all(updates)
      |> case do
        {0, nil} -> []
        {_count, messages} -> messages
      end
    end)
  end
end
