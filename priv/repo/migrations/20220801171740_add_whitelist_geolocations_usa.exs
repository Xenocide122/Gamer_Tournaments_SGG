defmodule Strident.Repo.Migrations.AddWhitelistGeolocationsUsa do
  use Ecto.Migration
  alias Ecto.Multi
  alias Strident.GeographicWhitelists.GeographicWhitelist
  alias Strident.Repo

  def change do
    Repo.transaction(
      fn ->
        query = """
        TRUNCATE TABLE geographic_whitelists RESTART IDENTITY;
        """

        Ecto.Adapters.SQL.query!(Repo.Local, query)
      end,
      timeout: :infinity
    )

    states = [
      %{state: "usak", features: [:stake, :play]},
      %{state: "usal", features: [:stake, :play]},
      %{state: "usar", features: [:stake, :play]},
      %{state: "usaz", features: [:stake, :play]},
      %{state: "usca", features: [:stake, :play]},
      %{state: "usco", features: [:stake, :play]},
      %{state: "usdc", features: [:stake, :play]},
      %{state: "usfl", features: [:stake, :play]},
      %{state: "usga", features: [:stake, :play]},
      %{state: "ushi", features: [:stake, :play]},
      %{state: "usid", features: [:stake, :play]},
      %{state: "usil", features: [:stake, :play]},
      %{state: "usin", features: [:stake, :play]},
      %{state: "usks", features: [:stake, :play]},
      %{state: "usky", features: [:stake, :play]},
      %{state: "usma", features: [:stake, :play]},
      %{state: "usmd", features: [:stake, :play]},
      %{state: "usme", features: [:stake, :play]},
      %{state: "usmi", features: [:stake, :play]},
      %{state: "usmn", features: [:stake, :play]},
      %{state: "usmo", features: [:stake, :play]},
      %{state: "usms", features: [:stake, :play]},
      %{state: "usnc", features: [:stake, :play]},
      %{state: "usnd", features: [:stake, :play]},
      %{state: "usne", features: [:stake, :play]},
      %{state: "usnh", features: [:stake, :play]},
      %{state: "usnj", features: [:stake, :play]},
      %{state: "usnm", features: [:stake, :play]},
      %{state: "usnv", features: [:stake, :play]},
      %{state: "usny", features: [:stake, :play]},
      %{state: "usoh", features: [:stake, :play]},
      %{state: "usok", features: [:stake, :play]},
      %{state: "usor", features: [:stake, :play]},
      %{state: "uspa", features: [:stake, :play]},
      %{state: "usri", features: [:stake, :play]},
      %{state: "ussc", features: [:stake, :play]},
      %{state: "ussd", features: [:stake, :play]},
      %{state: "ustx", features: [:stake, :play]},
      %{state: "usut", features: [:stake, :play]},
      %{state: "usva", features: [:stake, :play]},
      %{state: "uswa", features: [:stake, :play]},
      %{state: "uswi", features: [:stake, :play]},
      %{state: "uswv", features: [:stake, :play]},
      %{state: "uswy", features: [:stake, :play]},
      %{state: "usvt", features: [:play]},
      %{state: "usia", features: [:play]}
    ]

    for %{state: state, features: features} <- states,
        feature <- features,
        reduce: Multi.new() do
      multi ->
        Multi.insert(multi, {:state, state, feature}, fn _ ->
          %GeographicWhitelist{
            region_code: state,
            feature: feature,
            country_code: "us"
          }
        end)
    end
    |> Repo.transaction()
  end
end
