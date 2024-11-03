defmodule Strident.Repo.Migrations.AddAddressPostgisFieldsToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add(:lat, :float)
      add(:lng, :float)
      add(:full_address, :text)
    end

    execute("SELECT AddGeometryColumn ('tournaments', 'lat_lng', 4326, 'POINT', 2);")

    execute("CREATE INDEX tournaments_lat_lng_index ON tournaments USING GIST (lat_lng);")
  end
end
