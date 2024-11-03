defmodule Strident.Repo.Local.Migrations.CreateHomepagePopularGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :popular_game_index, :integer, null: true
    end

    create index(:games, [:popular_game_index])
  end
end
