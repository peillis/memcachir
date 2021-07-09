defmodule Memcachir.Mixfile do
  use Mix.Project

  @version "3.3.0"

  def project do
    [
      app: :memcachir,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps()
    ]
  end

  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger, :libring]
    ]
  end

  def description do
    "Memcached client, with connection pooling and cluster support."
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/peillis/memcachir"},
      maintainers: ["Enrique Martinez"]
    }
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:benchfella, "~> 0.3", only: :dev},
      {:credo, "~> 0.10", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:elasticachex, "~> 1.1"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:herd, "~> 0.4.3"},
      {:memcachex, "~> 0.5"},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
