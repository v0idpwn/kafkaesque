defmodule Kafkaesque.Migrations do
  use Ecto.Migration

  def up do
    create table(:kafkaesque_messages, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:state, :string, null: false, default: "pending")
      add(:topic, :string, null: false)
      add(:partition, :integer, null: false)
      add(:body, :binary)
      add(:attempt, :integer, null: false, default: 0)
      add(:attempted_by, :string)
      add(:attempted_at, :naive_datetime)
      add(:published_at, :naive_datetime)

      timestamps()
    end
  end

  def down do
    drop(table(:kafkaesque_messages))
  end
end
