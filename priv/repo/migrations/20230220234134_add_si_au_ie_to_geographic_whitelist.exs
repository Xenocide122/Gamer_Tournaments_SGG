defmodule Strident.Repo.Local.Migrations.AddSiAuIeToGeographicWhitelist do
  use Ecto.Migration
  alias Ecto.Multi
  alias Strident.GeographicWhitelists.GeographicWhitelist
  alias Strident.Repo

  def change do
    states = [
      %{region_code: "iel", country_code: "ie", feature: "stake"},
      %{region_code: "iel", country_code: "ie", feature: "wager"},
      %{region_code: "iel", country_code: "ie", feature: "play"},
      %{region_code: "si061", country_code: "si", feature: "stake"},
      %{region_code: "si061", country_code: "si", feature: "wager"},
      %{region_code: "si061", country_code: "si", feature: "play"},
      %{region_code: "auqld", country_code: "au", feature: "stake"},
      %{region_code: "auqld", country_code: "au", feature: "wager"},
      %{region_code: "auqld", country_code: "au", feature: "play"}
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
