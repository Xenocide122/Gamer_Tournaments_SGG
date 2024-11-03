defmodule Strident.Repo.Migrations.AddTypeToTournaments do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :type, :string, null: true
    end

    execute("""
    UPDATE tournaments SET type='open';
    """)

    alter table(:tournaments) do
      modify :type, :string, null: false
    end
  end

  def down do
    alter table(:tournaments) do
      remove :type
    end
  end
end
