defmodule Strident.Repo.Migrations.AddDefaultTimezoneChoiceToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :use_location_timezone, :boolean, null: true
    end

    execute("""
    update users set use_location_timezone = 'true'
    """)

    alter table(:users) do
      modify :use_location_timezone, :boolean, null: false, default: true
    end
  end

  def down do
    alter table(:users) do
      remove :use_location_timezone
    end
  end
end
