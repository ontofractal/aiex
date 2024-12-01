defmodule Ailixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :aiex,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_template, "~> 1.0"},
      {:ecto, "~> 3.12"},
      {:ex_doc, "~> 0.29.3", only: :dev, runtime: false},
      {:jason, "~> 1.4.0"},
      {:nimble_options, "~> 1.1"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:openai_ex, "~> 0.8.4"},
      {:req, "~> 0.5.0"}
    ]
  end
end
