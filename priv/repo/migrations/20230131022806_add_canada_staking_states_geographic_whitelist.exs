defmodule Strident.Repo.Local.Migrations.AddCanadaStakingStatesGeographicWhitelist do
  use Ecto.Migration
  alias Strident.Repo

  # @disable_ddl_transaction true

  def change do
    states = [
      %{region_code: "caab", country_code: "ca", feature: "stake"},
      %{region_code: "caab", country_code: "ca", feature: "wager"},
      %{region_code: "caab", country_code: "ca", feature: "play"},
      %{region_code: "cabc", country_code: "ca", feature: "stake"},
      %{region_code: "cabc", country_code: "ca", feature: "wager"},
      %{region_code: "cabc", country_code: "ca", feature: "play"},
      %{region_code: "camb", country_code: "ca", feature: "stake"},
      %{region_code: "camb", country_code: "ca", feature: "play"},
      %{region_code: "camb", country_code: "ca", feature: "wager"},
      %{region_code: "canb", country_code: "ca", feature: "stake"},
      %{region_code: "canb", country_code: "ca", feature: "play"},
      %{region_code: "canb", country_code: "ca", feature: "wager"},
      %{region_code: "canl", country_code: "ca", feature: "stake"},
      %{region_code: "canl", country_code: "ca", feature: "play"},
      %{region_code: "canl", country_code: "ca", feature: "wager"},
      %{region_code: "cant", country_code: "ca", feature: "stake"},
      %{region_code: "cant", country_code: "ca", feature: "play"},
      %{region_code: "cant", country_code: "ca", feature: "wager"},
      %{region_code: "cans", country_code: "ca", feature: "stake"},
      %{region_code: "cans", country_code: "ca", feature: "play"},
      %{region_code: "cans", country_code: "ca", feature: "wager"},
      %{region_code: "canu", country_code: "ca", feature: "stake"},
      %{region_code: "canu", country_code: "ca", feature: "play"},
      %{region_code: "canu", country_code: "ca", feature: "wager"},
      %{region_code: "cape", country_code: "ca", feature: "stake"},
      %{region_code: "cape", country_code: "ca", feature: "play"},
      %{region_code: "cape", country_code: "ca", feature: "wager"},
      %{region_code: "caqc", country_code: "ca", feature: "stake"},
      %{region_code: "caqc", country_code: "ca", feature: "play"},
      %{region_code: "caqc", country_code: "ca", feature: "wager"},
      %{region_code: "cask", country_code: "ca", feature: "stake"},
      %{region_code: "cask", country_code: "ca", feature: "play"},
      %{region_code: "cask", country_code: "ca", feature: "wager"},
      %{region_code: "cayt", country_code: "ca", feature: "stake"},
      %{region_code: "cayt", country_code: "ca", feature: "wager"},
      %{region_code: "cayt", country_code: "ca", feature: "play"}
    ]

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    for state <- states do
      {:ok, id} = Ecto.UUID.generate() |> Ecto.UUID.dump()

      Repo.query(
        "INSERT INTO geographic_whitelists(id, region_code, country_code, feature, inserted_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)",
        [id, state.region_code, state.country_code, state.feature, now, now]
      )
    end
  end
end
