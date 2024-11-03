defmodule Strident.Repo.Migrations.CreateTeamRosters do
  use Ecto.Migration

  def change do
    create table(:team_rosters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id), null: false
      add :valid_until, :naive_datetime, null: true
      timestamps()
    end
  end
end
