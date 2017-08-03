defmodule Memcachir.Mixfile do
  use Mix.Project

  @version "3.0.0"

  def project do
    [app: :memcachir,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
     deps: deps()]
  end

  # Type "mix help compile.app" for more information
  def application do
    [mod: {Memcachir, []},
     extra_applications: [:logger, :libring]]
  end

  def description do
    "Memcached client, with connection pooling and cluster support."
  end

  defp package do
    %{licenses: ["MIT"],
      links: %{"Github" => "https://github.com/peillis/memcachir"},
      maintainers: ["Enrique Martinez"]}
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [{:benchfella, "~> 0.3.0", only: :dev},
     {:credo, "~> 0.7", only: [:dev, :test]},
     {:dialyxir, "~> 0.5", only: :dev, runtime: false},
     {:elasticachex, "~> 1.0"},
     {:ex_doc, "~> 0.15", only: :dev},
     {:libring, "~> 1.1"},
     {:memcachex, "~> 0.4"},
     {:poolboy, "~> 1.5"},
     {:ex_statsd, github: "PagerDuty/ex_statsd", branch: "keep-socket-open"}]
  end
end
