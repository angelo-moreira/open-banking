defmodule OpenBanking.MixProject do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/angelo-moreira/open-banking"
  @version "0.1.0"

  def project do
    [
      app: :open_banking,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      maintainers: ["Angelo Moreira"],
      links: %{"GitHub" => @source_url}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OpenBanking.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:nimble_csv, "~> 1.1"}
    ]
  end

  # This is where we could run a pipeline task to make sure
  # standard such as credo are being implemented
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.reset --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
