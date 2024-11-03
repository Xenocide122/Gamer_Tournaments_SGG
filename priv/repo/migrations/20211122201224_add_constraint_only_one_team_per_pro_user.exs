defmodule Strident.Repo.Migrations.AddConstraintOnlyOneTeamPerProUser do
  use Ecto.Migration

  def change do
    create unique_index(:team_members, :user_id)
  end
end
