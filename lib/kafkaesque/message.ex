defmodule Kafkaesque.Message do
  @moduledoc """
  A Message to be published on Kafka
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type state ::
          :failed
          | :pending
          | :published
          | :publishing

  @type message :: %__MODULE__{
          topic: String.t(),
          state: state(),
          body: map(),
          attempt: pos_integer(),
          attempted_by: String.t(),
          attempted_at: NaiveDateTime.t(),
          published_at: NaiveDateTime.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "kafkaesque_messages" do
    field(:topic, :string)

    field(:state, Ecto.Enum,
      values: [:failed, :pending, :published, :publishing],
      default: :pending
    )

    field(:body, :map)
    field(:attempt, :integer, default: 0)
    field(:attempted_by, :string)
    field(:offset, :integer)

    field(:attempted_at, :naive_datetime)
    field(:published_at, :naive_datetime)

    timestamps()
  end

  def new(topic, body) do
    %__MODULE__{}
    |> cast(%{topic: topic, body: body}, [:topic, :body])
    |> validate_required([:topic, :body])
  end

  def set_published(message, offset), do: change(message, offset: offset, state: :published)
  def set_failed(message), do: change(message, state: :failed)
end
