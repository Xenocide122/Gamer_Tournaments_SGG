defmodule Strident.Repo.Migrations.CreateTeamRosterMembers do
  use Ecto.Migration

  def change do
    create table(:team_roster_members, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :team_roster_id, references(:team_rosters, on_delete: :nothing, type: :binary_id),
        null: false

      add :team_member_id, references(:team_members, on_delete: :nothing, type: :binary_id),
        null: false

      add :type, :string, null: false
      timestamps()
    end
  end
end
