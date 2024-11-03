defmodule Strident.Repo.Migrations.GamesAddDefaultGameBannerUrlColumn do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :default_game_banner_url, :string, null: true
    end
  end
end
