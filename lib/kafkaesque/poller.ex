defmodule Kafkaesque.Poller do
  @moduledoc """
  Polls the database for messages periodically and publishes them on Kafka
  """

  use GenServer

  require Logger

  alias Kafkaesque.Message
  alias Kafkaesque.Publisher
  alias Kafkaesque.Query

  @type activity :: :prepare_and_wait | :fetching | :publishing | :updating_fetched

  @type state :: %{
          client: :brod.client(),
          repo: Ecto.Repo.t(),
          doing: activity(),
          minimum_interval: pos_integer(),
          batch_size: pos_integer(),
          messages: list(Message.t()) | list(Ecto.Changeset.t()),
          running_since: NaiveDateTime.t(),
          last_started_fetching_at: NaiveDateTime.t(),
          last_updated_at: NaiveDateTime.t()
        }

  @defaults [
    batch_size: 100,
    minimum_interval: 300
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    {:ok, initial_state(opts), {:continue, :fetch_messages}}
  end

  defp initial_state(opts) do
    {:ok, client_id} = Publisher.client(opts)

    %{
      client: client_id,
      doing: :prepare_and_wait,
      repo:
        opts[:repo] || raise(ArgumentError, "Repo option is required to run Kafkaesque.Poller"),
      minimum_interval: opts[:minimum_interval] || @defaults[:minimum_interval],
      batch_size: opts[:minimum_interval] || @defaults[:batch_size],
      messages: [],
      running_sice: NaiveDateTime.utc_now(),
      last_started_fetching_at: nil,
      last_updated_at: NaiveDateTime.utc_now()
    }
  end

  @impl GenServer
  def handle_continue(:fetch_messages, state) do
    {:noreply,
     %{
       state
       | doing: :fetching,
         last_started_fetching_at: NaiveDateTime.utc_now(),
         last_updated_at: NaiveDateTime.utc_now()
     }, {:continue, :fetch_messages_2}}
  end

  def handle_continue(:fetch_messages_2, state) do
    {:ok, messages} = Query.pending_messages(state.repo, state.batch_size)

    new_state = %{
      state
      | doing: :publishing,
        messages: messages,
        last_updated_at: NaiveDateTime.utc_now()
    }

    {:noreply, new_state, {:continue, :publish_messages}}
  end

  def handle_continue(:publish_messages, state) do
    new_state = %{
      state
      | doing: :updating_fetched,
        messages: publish_messages(state.client, state.messages),
        last_updated_at: NaiveDateTime.utc_now()
    }

    {:noreply, new_state, {:continue, :update_fetched}}
  end

  def handle_continue(:update_fetched, state) do
    Enum.map(state.messages, &state.repo.update/1)

    new_state = %{state | doing: :prepare_and_wait, last_updated_at: NaiveDateTime.utc_now()}
    {:noreply, new_state, {:continue, :prepare_and_wait}}
  end

  def handle_continue(:prepare_and_wait, state) do
    new_state = %{state | messages: [], last_updated_at: NaiveDateTime.utc_now()}
    min = state.minimum_interval

    case NaiveDateTime.diff(NaiveDateTime.utc_now(), state.last_started_fetching_at, :millisecond) do
      t when t > min ->
        {:noreply, new_state, {:continue, :fetch_messages}}

      t ->
        Process.send_after(self(), :fetch_messages, min - t)
        {:noreply, new_state}
    end
  end

  @impl GenServer
  def handle_info(:fetch_messages, state) do
    {:noreply, state, {:continue, :fetch_messages}}
  end

  @impl GenServer
  def terminate(reason, state) do
    Logger.warn("Kafkaesque poller terminating with reason #{inspect(reason)}, updating messages")

    state.messages
    |> Enum.each(fn message ->
      case message do
        %Message{state: :published} = m ->
          m

        %Message{state: _state} = m ->
          m
          |> Message.set_failed()
          |> state.repo.update()

        %Ecto.Changeset{} = c ->
          state.repo.update(c)
      end
    end)
  end

  defp publish_messages(client, messages) do
    messages
    |> Enum.map(fn m ->
      client
      |> Publisher.publish(m)
      |> case do
        {:ok, offset} ->
          Message.set_published(m, offset)

        _error ->
          Message.set_failed(m)
      end
    end)
  end
end
