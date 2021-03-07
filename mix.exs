defmodule Kafkaesque.MixProject do
  use Mix.Project

  def project do
    [
      app: :kafkaesque,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:brod, "~> 3.15"},
      {:ecto, "~> 3.5"},
      {:ecto_sql, ">= 3.4.3"},
      {:jason, "~> 1.1"},
      {:postgrex, "~> 0.14"},
      {:telemetry, "~> 0.4"}
    ]
  end

  defp aliases do
    ["kafkaesque.migrate": [&migrate/1]]
  end

  defp migrate(_), do: Kafkaesque.Migrations.up()

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
