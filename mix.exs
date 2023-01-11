defmodule DuckDuckGoose.MixProject do
  use Mix.Project

  def project do
    [
      app: :duck_duck_goose,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {DuckDuckGoose.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.13"},
      {:plug_cowboy, "~>2.0"},
      {:redix, "~> 1.1"},
      {:castore, ">= 0.0.0"},
      {:jason, "~> 1.3"}
    ]
  end
end
