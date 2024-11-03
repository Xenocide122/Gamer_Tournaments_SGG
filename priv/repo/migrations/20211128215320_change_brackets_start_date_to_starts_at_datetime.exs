defmodule Strident.Repo.Migrations.ChangeBracketsStartDateToStartsAtDatetime do
  use Ecto.Migration

  def change do
    alter table(:brackets) do
      add :starts_at, :naive_datetime, null: true
    end

    execute("""
    UPDATE brackets set starts_at = start_date;
    """)

    alter table(:brackets) do
      remove :start_date
      modify :starts_at, :naive_datetime, null: false
    end
  end
end
