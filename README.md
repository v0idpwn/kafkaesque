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

Check the [Getting started](https://hexdocs.pm/kafkaesque/getting-started.html) guide in Hexdocs.

## Updating versions
To go from 1.0.0-rc.1 to 1.0.0-rc.2, an additional migration is needed:

```elixir
defmodule MyApp.Migrations.BumpKafkaesque do
  use Ecto.Migration

  def up, do: Kafkaesque.Migrations.up(:v1, :v2)
  def down, do: Kafkaesque.Migrations.down(:v2, :v1)
end
```

No extra steps are required if 1.0.0-rc.2 or a newer version was installed.
