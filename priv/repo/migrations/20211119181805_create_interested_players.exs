defmodule Strident.Repo.Migrations.CreateInterestedPlayers do
  use Ecto.Migration

  def change do
    create table(:interested_players, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :personal_name, :string, null: false
      add :team_name, :string, null: true
      add :email, :string, null: false
      add :game_profiles, {:array, :string}, null: false
      add :social_profiles, {:array, :string}, null: false
      add :favorite_games, {:array, :string}, null: false

      timestamps()
    end
  end
end
