defmodule PAEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/LGuichet/PAEx"

  def project do
    [
      app: :pa_ex,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description:
        "Plateforme Agréée Elixir — accredited partner dematerialization platform (PDP) " <>
          "for French e-invoicing (facturation électronique) and e-reporting",
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      mod: {PAEx.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Ash Framework
      {:ash, "~> 3.4"},
      {:ash_postgres, "~> 2.4"},
      {:ash_phoenix, "~> 2.1"},
      {:ash_json_api, "~> 1.4"},

      # Phoenix
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0"},

      # Database
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19"},

      # Auth
      {:bcrypt_elixir, "~> 3.1"},

      # HTTP client (for PPF integration)
      {:req, "~> 0.5"},

      # XML generation (Factur-X / UBL / CII)
      {:sweet_xml, "~> 0.7"},
      {:xml_builder, "~> 2.3"},

      # JSON
      {:jason, "~> 1.4"},

      # UUID
      {:uniq, "~> 0.6"},

      # Telemetry
      {:bandit, "~> 1.5"},
      {:dns_cluster, "~> 0.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},

      # Dev / test
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.1", only: :test},
      {:faker, "~> 0.18", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
