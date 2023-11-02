# Getting started

First, you need to migrate your database to create the outbox. Create a
migration with Ecto and add the following:

```elixir
defmodule MyApp.Repo.Migrations.AddKafkaesque
  def up do
    Kafkaesque.Migrations.up()
  end

  def down do
    Kafkaesque.Migrations.down()
  end
end
```

Then, you must define an outbox module, associated with the Repo you
ran the Kafkaesque migrations on. For example:

```elixir
defmodule MyApp.Outbox do
  use Kafkaesque, repo: MyApp.Repo

  # Optional, sets the partition for the message. Should return an integer
  # Defaults to returning 0.
  def partition(_topic, _key, _body) do
    Enum.random(0..1)
  end

  # Optional, encodes the body of the message, should return a String.
  # Defaults to the identity function.
  def encode(body) do
    Jason.encode!(body)
  end
end
```

Finally, you should start a `Kafkaesque` instance in your supervision tree.
For example:

```elixir
defmodule MyApp.Application do
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {MyApp.Outbox, [client_opts: [client_id: :my_client, brokers: [{"localhost, 9092"}]]]},
    ]
  end
end
```

Done! Now you can publish messages. Try it out with:

```elixir
MyApp.Outbox.publish("topic", "mykey", %{hello: :kafka})`
```
