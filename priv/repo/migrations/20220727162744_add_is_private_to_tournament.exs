defmodule Strident.Repo.Migrations.AddIsPublicToTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :is_public, :boolean, default: false
    end
  end
end
