defmodule Strident.Repo.Migrations.MakeRegistrationsOpenAtNonNullable do
  use Ecto.Migration

  def change do
    execute """
    UPDATE tournaments AS t SET registrations_open_at=t.starts_at WHERE registrations_open_at IS NULL
    """

    alter table(:tournaments) do
      modify :registrations_open_at, :naive_datetime, null: false
    end
  end
end
