defmodule Strident.Repo.Migrations.AddDeletedAtToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :deleted_at, :naive_datetime, null: true
    end
  end
end
