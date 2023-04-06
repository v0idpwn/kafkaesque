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
