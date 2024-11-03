defmodule Strident.Repo.Migrations.CreateGeographicWhitelists do
  use Ecto.Migration

  def change do
    create table(:geographic_whitelists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :state, :string
      add :country, :string
      add :feature, :string

      timestamps()
    end
  end
end
