defmodule Strident.Repo.Migrations.AddBannerToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :banner_url, :string, null: true
    end
  end
end
