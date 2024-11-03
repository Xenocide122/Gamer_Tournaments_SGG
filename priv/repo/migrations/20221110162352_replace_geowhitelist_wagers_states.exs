defmodule Strident.Repo.Local.Migrations.ReplaceGeowhitelistWagersStates do
  use Ecto.Migration
  alias Ecto.Multi
  alias Strident.GeographicWhitelists.GeographicWhitelist
  alias Strident.Repo

  def change do
    states = [
      "usal",
      "usak",
      "usca",
      "usco",
      "usde",
      "usga",
      "ushi",
      "usid",
      "usil",
      "usia",
      "usks",
      "usky",
      "usme",
      "usma",
      "usmi",
      "usmn",
      "usms",
      "usmo",
      "usnv",
      "usnh",
      "usnj",
      "usny",
      "usnc",
      "usnd",
      "usoh",
      "usok",
      "usor",
      "uspa",
      "usri",
      "ustx",
      "usvt",
      "usva",
      "uswa",
      "uswv",
      "uswi",
      "uswy",
      "usdc"
    ]

    Repo.transaction(
      fn ->
        query = """
        DELETE FROM geographic_whitelists WHERE feature='wager';
        """

        Ecto.Adapters.SQL.query!(Repo.Local, query)
      end,
      timeout: :infinity
    )

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
