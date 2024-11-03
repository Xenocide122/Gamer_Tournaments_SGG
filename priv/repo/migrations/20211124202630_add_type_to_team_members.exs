defmodule Strident.Repo.Migrations.AddTypeToTeamMembers do
  use Ecto.Migration

  def up do
    alter table(:team_members) do
      add :type, :string, null: true
    end

    execute("""
    UPDATE team_members SET type='member';
    """)

    alter table(:team_members) do
      modify :type, :string, null: false
    end
  end

  def down do
    alter table(:team_members) do
      remove :type
    end
  end
end
