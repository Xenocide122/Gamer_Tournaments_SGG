defmodule Strident.Repo.Migrations.RemoveOnlyOneTeamRestriction do
  use Ecto.Migration

  def change do
    drop unique_index(:team_members, [:user_id])
  end
end
