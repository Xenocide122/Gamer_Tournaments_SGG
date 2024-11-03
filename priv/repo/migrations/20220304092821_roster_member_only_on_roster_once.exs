defmodule Strident.Repo.Migrattions.RosterMemberOnlyOnRosterOnce do
  use Ecto.Migration

  def change do
    execute("""
    DELETE FROM team_roster_members a USING team_roster_members b
    WHERE a.id > b.id
    AND a.team_roster_id = b.team_roster_id
    AND a.team_member_id = b.team_member_id;
    """)

    create unique_index(:team_roster_members, [:team_roster_id, :team_member_id])
  end
end
