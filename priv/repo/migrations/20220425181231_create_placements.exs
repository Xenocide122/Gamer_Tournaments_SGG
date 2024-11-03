defmodule Strident.Repo.Migrations.CreatePlacements do
  use Ecto.Migration

  def change do
    create table(:placements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :rank, :integer
      add :total_players, :integer
      add :source, :text
      add :canonical_url, :text
      add :is_external, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:placements, [:user_id])
    create index(:placements, [:tournament_id])
    create unique_index(:placements, [:user_id, :canonical_url])
  end
end
