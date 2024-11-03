defmodule Strident.Repo.Migrations.ModifyGeographicWhitelists do
  use Ecto.Migration

  def change do
    alter table("geographic_whitelists") do
      modify :state, :string, null: false
      modify :country, :string, null: false
      modify :feature, :string, null: false
    end
  end
end
