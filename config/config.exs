use Mix.Config

config :kafkaesque, Kafkaesque.Test.Repo,
  priv: "test/support/",
  url: "postgres://postgres@localhost:5432/oban_test",
  password: "postgres",
  pool_size: 10

config :kafkaesque,
  ecto_repos: [Kafkaesque.Test.Repo]
