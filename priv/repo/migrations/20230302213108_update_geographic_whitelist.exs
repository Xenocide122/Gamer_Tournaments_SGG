defmodule Strident.Repo.Local.Migrations.UpdateGeographicWhitelist do
  use Ecto.Migration

  alias Strident.GeographicWhitelists.GeographicWhitelist
  alias Strident.Repo

  @disable_ddl_transaction true
  @disable_migration_lock true

  @states [
    %{
      country_code: "us",
      feature: :stake,
      region_code: "ustn",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :stake,
      region_code: "usla",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :stake,
      region_code: "usct",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :stake,
      region_code: "usmt",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :stake,
      region_code: "usde",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :wager,
      region_code: "ustn",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :wager,
      region_code: "usla",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :wager,
      region_code: "usct",
      gateway_options: ["paypal", "ach"]
    },
    %{
      country_code: "us",
      feature: :wager,
      region_code: "usmt",
      gateway_options: ["paypal", "ach"]
    }
  ]

  def up do
    maybe_add_entries(@states)
  end

  def down, do: :ok

  def maybe_add_entries(states) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    for state <- states do
      repo().insert(
        %GeographicWhitelist{
          region_code: state.region_code,
          country_code: state.country_code,
          feature: state.feature,
          gateway_options: state.gateway_options
        },
        on_conflict: :nothing
      )
    end
  end
end
