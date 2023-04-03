# Kafkaesque
Kafkaesque is a transactional outbox built for PostgreSQL and, primarily, Kafka.

- Transactional safety for messages: if they were created, they **will** be
eventually published. They're only created if the transaction commits
- Ordering: messages are published sequentially for topic/partition combinations
- Shutdown safety: has graceful shutdown and rescue for cases where it doesn't
happen.
- Garbage collection: outbox table is periodically cleaned

```plantuml
@startuml
skinparam componentStyle uml2
skinparam linetype ortho

database "Kafka" {
  [Broker]
}

node "Application" {
  package "Kafkaesque" {
    folder "Publish pipeline" {
      [Producer] -> [Publisher]
      [Publisher] -> [Acknowledger]
    }
    [Rescuer]
    [Garbage Collector]
  }


  package "MyApp" {
    [Context] --> MyApp.Kafka
    MyApp.Kafka --> MyApp.Repo: write
  }
}


database "PostgreSQL" {
  [Messages table]
}


[Producer] --> MyApp.Repo: read
[Acknowledger] --> MyApp.Repo: write
[Rescuer] --> MyApp.Repo: write
[Garbage Collector] --> MyApp.Repo: write
MyApp.Repo --> [Messages table]
[Publisher] -up-> [Broker]: publish
[Broker] -down-> [Publisher]: ack

@enduml
```
