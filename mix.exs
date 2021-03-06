defmodule Ballistic.Mixfile do
  use Mix.Project

  def project do
    [app: :ballistic,
     version: "0.1.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     elixirc_paths: elixirc_paths(Mix.env)
   ]
  end

  # This makes sure your factory and any other modules in test/support are compiled
  # when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :slack, :gproc, :poison, :hulaaki, :websocket_client, :postgrex],
      mod: {Ballistic, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:hulaaki, "~> 0.0.4"},
      {:slack, "~> 0.11.0"},
      {:poison, "~> 3.1"},
      {:gproc, "~> 0.6.1"},
      {:postgrex, "~> 0.13"},
      {:ecto, "~> 2.1"},

      # Test
      {:ex_machina, "~> 2.0", only: :test},

      # Deployment
      {:distillery, "~> 1.2"}
    ]
  end
end
