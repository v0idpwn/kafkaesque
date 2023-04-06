# Kafkaesque

Kafkaesque is a transactional outbox built for PostgreSQL and, primarily, Kafka.

- Transactional safety for messages: if they were created, they **will** be
eventually published. They're only created if the transaction commits
- Ordering: messages are published sequentially for topic/partition combinations
- Shutdown safety: has graceful shutdown and rescue for cases where it doesn't
happen.
- Observability: all operations publish telemetry events
- Garbage collection: outbox table is periodically cleaned

![Basic diagram](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/v0idpwn/kafkaesque/master/diagrams/basic.iuml)

## Installation

Add :kafkaesque to the list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:kafkaesque, "~> 1.0-rc.0"}
  ]
end
```

## Getting started

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

Then, you must define a publisher module, associated with the Repo you
ran the Kafkaesque migrations on. For example:

```elixir
defmodule MyApp.KafkaPublisher do
  use Kafkaesque, repo: MyApp.Repo

  # Optional, sets the partition for the message. Should return an integer
  # Defaults to returning 0.
  def partition(_topic, _body) do
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
      {Kafkaesque, [repo: MyApp.Repo, client_opts: [client_id: :my_client, brokers: [{"localhost, 9092"}]]]},
    ]
  end
end
```

Done! Now you can publish messages. Try it out with:

```elixir
MyApp.KafkaPublisher.publish("topic", %{hello: :kafka})`
```
