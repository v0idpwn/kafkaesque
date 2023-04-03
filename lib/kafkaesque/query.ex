defmodule Kafkaesque.Query do
  @moduledoc false

  import Ecto.Query

  alias Kafkaesque.Message

  # Random bigint we use for advisory locking.
  @xact_lock_key 5_184_639_755_711_623_169

  @doc """
  Returns pending messages for topic/partition combinations that can accept
  publications.

  Sets those messages to the `publishing` state.
  """
  @spec pending_messages(Ecto.Repo.t(), pos_integer()) ::
          {:ok, {integer(), list(Message.t())}} | {:error, atom()}
  def pending_messages(repo, demand) do
    publishing_topic_partitions =
      Message
      |> group_by([m], [m.topic, m.partition])
      |> where([m], m.state == :publishing)
      |> select([m], [:topic, :partition])

    subset =
      Message
      |> select([m], m.id)
      |> join(:left, [m], tp in ^subquery(publishing_topic_partitions),
        on: m.topic == tp.topic and m.partition == tp.partition
      )
      |> where([m, tp], is_nil(tp.topic))
      |> where([m], m.state in [:pending, :failed])
      |> order_by([m], m.id)
      |> limit(^demand)

    repo.transaction(fn ->
      repo.query!("SELECT pg_advisory_xact_lock($1)", [@xact_lock_key])

      Message
      |> where([m], m.id in subquery(subset))
      |> select([m, _], m)
      |> update([m],
        set: [
          state: :publishing,
          attempted_at: fragment("CURRENT_TIMESTAMP"),
          attempted_by: ^inspect(node())
        ],
        inc: [attempt: 1]
      )
      |> repo.update_all([])
      |> case do
        {0, nil} -> []
        {count, messages} -> {count, messages}
      end
    end)
  end

  @spec update_success_batch(Ecto.Repo.t(), [pos_integer()]) :: :ok
  def update_success_batch(repo, ids) do
    update_batch(repo, ids, "published")
  end

  @spec update_failed_batch(Ecto.Repo.t(), [pos_integer()]) :: :ok
  def update_failed_batch(repo, ids) do
    update_batch(repo, ids, "failed")
  end

  defp update_batch(repo, ids, new_state) do
    from(Message)
    |> where([m], m.id in ^ids)
    |> repo.update_all(set: [state: new_state])
  end

  @spec rescue_publishing(Ecto.Repo.t(), time_limit_ms :: pos_integer()) ::
          {pos_integer(), nil}
  def rescue_publishing(repo, time_limit_ms) do
    time_limit_s = time_limit_ms / 1000

    from(Message)
    |> where([m], m.state == :publishing)
    |> where([m], m.attempted_at < ago(^time_limit_s, "second"))
    |> update([m], set: [state: :pending])
    |> repo.update_all([])
  end

  @spec garbage_collect(Ecto.Repo.t(), time_limit_ms :: pos_integer()) ::
          {pos_integer(), nil}
  def garbage_collect(repo, time_limit_ms) do
    time_limit_s = time_limit_ms / 1000

    from(Message)
    |> where([m], m.state == :published)
    |> where([m], m.attempted_at < ago(^time_limit_s, "second"))
    |> repo.delete_all()
  end
end
