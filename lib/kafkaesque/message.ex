defmodule Kafkaesque.Message do
  @moduledoc """
  Application-side representation of messages, published or not
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type state() ::
          :failed
          | :pending
          | :published
          | :publishing

  @type t() :: %__MODULE__{
          state: state(),
          topic: String.t(),
          partition: integer(),
          body: String.t(),
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
    field(:body, :string)
    field(:attempt, :integer, default: 0)
    field(:attempted_by, :string)
    field(:offset, :integer)

    field(:attempted_at, :naive_datetime)
    field(:published_at, :naive_datetime)

    timestamps()
  end

  @spec new(String.t(), String.t(), String.t()) :: Ecto.Changeset.t()
  def new(topic, partition, body) do
    %__MODULE__{}
    |> cast(%{topic: topic, partition: partition, body: body}, [
      :topic,
      :partition,
      :body
    ])
    |> validate_required([:topic, :partition, :body])
  end
end
