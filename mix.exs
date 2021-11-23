defmodule Familiar.MixProject do
  use Mix.Project

  @scm_url "https://github.com/Multiverse-io/familiar"
  @version "0.1.3"

  def project do
    [
      app: :familiar,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      source_url: @scm_url,
      description: """
      Ecto helpers for creating database views and functions
      """,
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :postgrex, :ecto]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0", only: :test},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      links: %{"GitHub" => @scm_url},
      licenses: ["MIT"]
    ]
  end

  defp docs do
    [
      main: "Familiar",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/familiar",
      source_url: @scm_url
    ]
  end
end
