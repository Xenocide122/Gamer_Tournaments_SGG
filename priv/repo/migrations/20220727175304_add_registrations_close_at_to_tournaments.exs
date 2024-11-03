defmodule Strident.Repo.Migrations.AddRegistrationsCloseAtToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :registrations_close_at, :naive_datetime, null: true
    end

    execute("UPDATE tournaments SET registrations_close_at = starts_at - INTERVAL '2 HOURS'")

    alter table(:tournaments) do
      modify :registrations_close_at, :naive_datetime, null: false
    end
  end
end
