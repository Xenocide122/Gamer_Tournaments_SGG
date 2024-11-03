defmodule Strident.Repo.Migrations.AddDeletedAtToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :deleted_at, :naive_datetime, null: true
    end
  end
end
