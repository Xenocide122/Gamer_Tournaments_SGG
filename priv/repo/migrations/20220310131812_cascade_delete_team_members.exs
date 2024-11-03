defmodule Strident.Repo.Migrations.CascadeDeleteTeamMembers do
  use Ecto.Migration

  def up do
    drop(constraint(:team_roster_members, "team_roster_members_team_member_id_fkey"))

    alter table(:team_roster_members) do
      modify :team_member_id,
             references(:team_members, on_delete: :delete_all, type: :binary_id),
             null: false
    end
  end

  def down do
    drop(constraint(:team_roster_members, "team_roster_members_team_member_id_fkey"))

    alter table(:team_roster_members) do
      modify :team_member_id,
             references(:team_members, on_delete: :nothing, type: :binary_id),
             null: false
    end
  end
end
