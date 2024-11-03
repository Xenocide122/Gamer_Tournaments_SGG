defmodule Strident.MixProject do
  use Mix.Project

  def project do
    [
      app: :strident,
      version: "0.1.0",
      elixir: "~> 1.14.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      elixirc_options: [warning_as_errors: true],
      preferred_cli_env: [quality: :test],
      dialyzer: [
        plt_add_apps: [:mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],

      # Docs
      name: "Strident",
      source_url: "https://github.com/play-oxygen/strident",
      homepage_url: "https://grilla.gg",
      docs: [
        # The main page in the docs
        main: "Strident",
        logo: "priv/static/images/stride-header-footer-logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Strident.Application, []},
      extra_applications: [:logger, :oauth2, :runtime_tools, :hcaptcha, :crypto, :ueberauth_apple]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(env) do
    cond do
      env in [:dev, :test] ->
        ["lib", "test/support", "seeds", "credo_checks", "test/support/factories"]

      System.get_env("IS_STAGING") ->
        ["lib", "test/support", "seeds", "test/support/factories"]

      true ->
        ["lib"]
    end
  end

  # Specifies your project dependencies.
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:appsignal_phoenix, "~> 2.0"},
      {:bcrypt_elixir, "~> 2.0"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.8"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.16"},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:phoenix_view, "~> 2.0"},
      {:esbuild, "~> 0.4.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:oauth2, "~> 2.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.6", override: true},
      {:cors_plug, "~> 2.0"},
      {:ex_cldr, "~> 2.33"},
      {:ex_cldr_territories, "~> 2.4.0"},
      {:ex_cldr_units, "~> 3.13"},
      {:ex_cldr_dates_times, "~> 2.11.0"},
      {:ex_cldr_languages, "~> 0.3.3"},
      {:ex_cldr_lists, "~> 2.10"},
      {:ex_cldr_locale_display, "~> 1.3"},
      {:ex_money, "~> 5.8"},
      {:ex_money_sql, "~> 1.5"},
      {:sage, ">= 0.6.0"},
      {:libgraph, "~> 0.7", only: :dev},
      {:segment, "~> 0.2.6"},
      {:mox, "~> 1.0", only: [:dev, :test]},
      {:math, "~> 0.7"},
      {:absinthe, "~> 1.6"},
      {:absinthe_plug, "~> 1.5"},
      {:appsignal, "~> 2.2"},
      {:ex_machina, "~> 2.7", ex_machina_faker_opts()},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.11.1", only: [:dev, :test], runtime: false},
      {:burnex, "~> 3.1.0"},
      {:dataloader, "~> 2.0"},
      {:slugify, "~> 1.3"},
      {:oban, "~> 2.10"},
      {:timex, "~> 3.7"},
      {:recase, "~> 0.5"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8.3"},
      {:remote_ip, "~> 1.0"},
      {:finch, "~> 0.10"},
      {:tesla, "~> 1.4"},
      {:neuron, "~> 5.0.0"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.3"},
      {:imgproxy, "~> 3.0"},
      {:sweet_xml, "~> 0.7.3"},
      {:earmark, "1.4.15"},
      {:earmark_parser, "1.4.15"},
      {:ex_doc, "0.26.0", only: :dev, runtime: false},
      {:typed_ecto_schema, "~> 0.4"},
      {:html_sanitize_ex, "~> 1.4"},
      {:hcaptcha, "~> 0.0.1"},
      {:scrivener_ecto, "~> 2.7"},
      {:google_api_you_tube, "~> 0.42"},
      {:faker, "~> 0.17.0", ex_machina_faker_opts()},
      {:combination, "~> 0.0.3"},
      {:quantum, "~> 3.0"},
      {:quantum_storage_persistent_ets, "~> 1.0"},
      {:gearbox, "~> 0.3.3"},
      {:httpoison, "~> 1.8"},
      {:floki, "~> 0.32.1"},
      {:ueberauth, "~> 0.9.0"},
      {:ueberauth_discord, "~> 0.7.0"},
      {:ueberauth_apple, "~> 0.4"},
      {:geo, "~> 3.4"},
      {:geo_postgis, "~> 3.4"},
      {:expletive, "~> 0.1.5"},
      {:number, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto_nested_changeset, "~> 0.2.0"},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:ecto_anon, "~> 0.5.0"},
      {:fly_postgres, "~> 0.3.1"},
      {:uuid, "~> 1.1"},
      {:cloak_ecto, "~> 1.2.0"},
      {:pigeon, "~> 2.0.0-rc.1"},
      {:csv, "~> 3.0"},
      {:sftp_client, "~> 1.4"},
      {:mint, "~> 1.4", override: true},
      {:prom_ex, "~> 1.7", override: true},
      {:req, "~> 0.3"},
      {:highlander, "~> 0.2.1"},
      {:net_address, "~> 0.2.0"},
      {:benchee, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp releases do
    [
      strident: [
        include_executables_for: [:unix]
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      quality: [
        "format",
        "credo --strict",
        "sobelow --config",
        "deps.audit",
        "dialyzer --format dialyxir",
        "test"
      ],
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test.ci": ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "cmd --cd assets npm run deploy",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end

  # We want to remove :ex_machina and :faker from Production env.
  defp ex_machina_faker_opts do
    if is_nil(System.get_env("IS_STAGING")) do
      [only: [:dev, :test]]
    else
      []
    end
  end
end
