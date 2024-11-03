defmodule Strident.Repo.Migrations.AddTypeToPartyMembers do
  use Ecto.Migration

  def up do
    alter table(:party_members) do
      add :type, :string, null: true
    end

    execute("""
    UPDATE party_members SET type='member';
    """)

    alter table(:party_members) do
      modify :type, :string, null: false
    end
  end

  def down do
    alter table(:party_members) do
      remove :type
    end
  end
end
