defmodule Strident.Repo.Migrations.AddStarterToRosterMember do
  use Ecto.Migration

  def up do
    alter table(:team_roster_members) do
      add :is_starter, :boolean, null: true
    end

    execute("""
    	UPDATE team_roster_members
    	SET is_starter = true;
    """)

    alter table(:team_roster_members) do
      modify :is_starter, :boolean, null: false
    end
  end

  def down do
    alter table(:team_roster_members) do
      remove :is_starter
    end
  end
end
