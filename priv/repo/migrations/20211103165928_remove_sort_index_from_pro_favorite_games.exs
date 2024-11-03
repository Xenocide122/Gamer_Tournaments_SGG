defmodule Strident.Repo.Migrations.RemoveSortIndexFromProFavoriteGames do
  use Ecto.Migration

  def change do
    alter table(:pro_favorite_games) do
      remove :sort_index
    end
  end
end
