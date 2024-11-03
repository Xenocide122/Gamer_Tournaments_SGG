defmodule Strident.Repo.Local.Migrations.AddLogoToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :logo_url, :string, null: true
    end
  end
end
