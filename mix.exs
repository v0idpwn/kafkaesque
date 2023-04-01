defmodule Kafkaesque.MixProject do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :kafkaesque,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      package: package(),
      name: "Kafkaesque",
      source_url: "https://github.com/v0idpwn/kafkaesque"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 1.0"},
      {:brod, "~> 3.15"},
      {:ecto, "~> 3.5"},
      {:ecto_sql, ">= 3.4.3"},
      {:jason, "~> 1.1"},
      {:postgrex, "~> 0.14"},
      {:telemetry, "~> 0.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Transactional outbox for kafka"
  end

  defp package do
    [
      name: "kafkaesque",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/v0idpwn/kafkaesque"}
    ]
  end

  defp aliases do
    ["kafkaesque.migrate": [&migrate/1]]
  end

  defp migrate(_), do: Kafkaesque.Migrations.up()

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
