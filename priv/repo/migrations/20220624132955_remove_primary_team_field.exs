defmodule Strident.Repo.Migrations.RemovePrimaryTeamField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :primary_team_id
    end
  end
end
