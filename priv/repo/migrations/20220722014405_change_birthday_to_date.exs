defmodule Strident.Repo.Migrations.ChangeBirthdayToDate do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :birthdaytmp, :date, null: true
    end

    execute("""
    UPDATE users SET birthdaytmp = birthday :: DATE WHERE birthday IS NOT NULL;
    """)

    alter table(:users) do
      remove :birthday
    end

    rename table(:users), :birthdaytmp, to: :birthday
  end

  def down do
    alter table(:users) do
      add :birthdaytmp, :naive_datetime, null: true
    end

    execute("""
    UPDATE users SET birthdaytmp = birthday + time '00:00:00' WHERE birthday IS NOT NULL;
    """)

    alter table(:users) do
      remove :birthday
    end

    rename table(:users), :birthdaytmp, to: :birthday
  end
end
