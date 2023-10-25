defmodule Kafkaesque.Migrations do
  use Ecto.Migration

  # Functions independent from version
  def up() do
    create table(:kafkaesque_messages, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:state, :string, null: false, default: "pending")
      add(:topic, :string, null: false)
      add(:partition, :integer, null: false)
      add(:key, :binary, default: "")
      add(:body, :binary)
      add(:attempt, :integer, null: false, default: 0)
      add(:attempted_by, :string)
      add(:attempted_at, :naive_datetime)
      add(:published_at, :naive_datetime)

      timestamps()
    end
  end

  def down() do
    drop(table(:kafkaesque_messages))
  end

  def up(current, next)

  def up(:v1, :v2) do
    alter table(:kafkaesque_messages) do
      add(:key, :binary, default: "", null: false)
    end
  end

  def down(current, previous)

  def down(:v2, :v1) do
    alter table(:kafkaesque_messages) do
      drop(:key)
    end
  end
end
