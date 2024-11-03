defmodule Strident.Repo.Local.Migrations.AddNewFeatureToGeographicWhitelistStatesWager do
  use Ecto.Migration
  alias Ecto.Multi
  alias Strident.Repo
  alias Strident.GeographicWhitelists.GeographicWhitelist

  def change do
    states = [
      "usaz",
      "usar",
      "usct",
      "usde",
      "usfl",
      "usin",
      "usla",
      "usmd",
      "usmt",
      "usne",
      "usnm",
      "ussc",
      "ussd",
      "ustn",
      "usut"
    ]

    for state <- states, reduce: Multi.new() do
      multi ->
        Multi.insert(multi, {:state, state}, fn _ ->
          %GeographicWhitelist{
            region_code: state,
            feature: :wager,
            country_code: "us"
          }
        end)
    end
    |> Repo.transaction()
  end
end
