defmodule Strident.Repo.Local.Migrations.CreateGameGenres do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :default_player_count, :integer
    end

    create table(:genres, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :genre_name, :text
      add :slug, :string, null: false
      add :hidden, :boolean, default: true
    end

    create unique_index(:genres, [:slug])

    create table(:game_genres, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :genre_id, references(:genres, on_delete: :nothing, type: :binary_id), null: false
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id), null: false
    end

    create unique_index(:game_genres, [:genre_id, :game_id])
    create index(:game_genres, :game_id)
  end
end
