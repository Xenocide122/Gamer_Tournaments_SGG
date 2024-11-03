defmodule Strident.Repo.Migrations.AddCheckTimezoneToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :check_timezone, :boolean, null: true
    end

    execute("""
    update users set check_timezone = 'true'
    """)

    alter table(:users) do
      modify :check_timezone, :boolean, null: false, default: true
    end
  end

  def down do
    alter table(:users) do
      remove :check_timezone
    end
  end
end
