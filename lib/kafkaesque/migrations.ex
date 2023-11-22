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

    create_if_not_exists(index(:kafkaesque_messages, [:state]))
  end

  def down() do
    drop(table(:kafkaesque_messages))
  end

  def up(current, next)

  def up(nil, :v1) do
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

  def up(:v1, :v2) do
    alter table(:kafkaesque_messages) do
      add_if_not_exists(:key, :binary, default: "", null: false)
    end
  end

  def up(:v2, :v3) do
    create_if_not_exists(index(:kafkaesque_messages, [:state]))
  end

  def down(current, previous)

  def down(:v3, :v2) do
    drop(index(:kafkaesque_messages, [:state]))
  end

  def down(:v2, :v1) do
    alter table(:kafkaesque_messages) do
      remove_if_exists(:key, :binary)
    end
  end

  def down(:v1, nil) do
    drop(table(:kafkaesque_messages))
  end
end
