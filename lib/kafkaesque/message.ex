defmodule Kafkaesque.Message do
  @moduledoc """
  Application-side representation of messages, published or not
  """

  use Ecto.Schema
  import Ecto.Changeset

  defmodule Data do
    use Ecto.Type

    def type, do: :binary

    def cast(term), do: {:ok, term}

    def load(data) when is_binary(data), do: {:ok, :erlang.binary_to_term(data)}

    def dump(term), do: {:ok, :erlang.term_to_binary(term)}
  end

  @type state() ::
          :failed
          | :pending
          | :published
          | :publishing

  @type t() :: %__MODULE__{
          state: state(),
          topic: String.t(),
          partition: integer(),
          body: term(),
          attempt: pos_integer(),
          attempted_by: String.t() | nil,
          attempted_at: NaiveDateTime.t() | nil,
          published_at: NaiveDateTime.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "kafkaesque_messages" do
    field(:topic, :string)

    field(:state, Ecto.Enum,
      values: [:failed, :pending, :published, :publishing],
      default: :pending
    )

    field(:partition, :integer)
    field(:key, :string, default: "")
    field(:body, __MODULE__.Data, default: %{})
    field(:attempt, :integer, default: 0)
    field(:attempted_by, :string)

    field(:attempted_at, :naive_datetime)
    field(:published_at, :naive_datetime)

    timestamps()
  end

  @spec new(String.t(), integer(), String.t(), term()) :: Ecto.Changeset.t()
  def new(topic, partition, key, body) do
    %__MODULE__{}
    |> cast(%{topic: topic, partition: partition, body: body, key: key}, [
      :topic,
      :partition,
      :key,
      :body
    ])
    |> validate_required([:topic, :partition, :body])
  end
end
