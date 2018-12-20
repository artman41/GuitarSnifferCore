defmodule GuitarSnifferCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :guitar_sniffer_core,
      version: "1.1",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {GuitarSnifferCore.App, []},
      applications: [
        :logger,
        :ranch
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:ranch, "~> 1.7"},
      {:distillery, "~> 2.0.12"}
    ]
  end
end
