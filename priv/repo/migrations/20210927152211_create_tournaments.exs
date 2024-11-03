defmodule Strident.Repo.Migrations.CreateTournaments do
  use Ecto.Migration

  def change do
    create table(:tournaments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :starts_at, :naive_datetime, null: false
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:tournaments, [:game_id])
  end
end
