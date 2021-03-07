defmodule Kafkaesque.Test.Repo.Migrations.CreateKafkaesqueMessages do
  use Ecto.Migration

  def up, do: Kafkaesque.Migrations.up()
  def down, do: Kafkaesque.Migrations.down()
end
