defmodule Strident.Repo.Migrations.SetTeamDescriptionAndLogoUrlAsNullableField do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      modify :description, :string, null: true
      modify :logo_url, :string, null: true
    end
  end
end
