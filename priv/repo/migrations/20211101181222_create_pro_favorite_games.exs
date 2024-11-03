defmodule Strident.Repo.Migrations.CreateProFavoriteGames do
  use Ecto.Migration

  def change do
    create table(:pro_favorite_games, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :pro_id, references(:pros, on_delete: :nothing, type: :binary_id), null: false
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id), null: false
      add :sort_index, :integer, null: false
    end

    create unique_index(:pro_favorite_games, [:pro_id, :game_id])
    create unique_index(:pro_favorite_games, [:pro_id, :sort_index])
    create index(:pro_favorite_games, :pro_id)
    create index(:pro_favorite_games, :game_id)
  end
end
