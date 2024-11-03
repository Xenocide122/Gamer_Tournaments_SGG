defmodule Strident.Repo.Migrations.AddTeamFolowerTable do
  use Ecto.Migration

  def change do
    create table(:team_followers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false
      add :follower_id, references(:users, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:team_followers, [:team_id, :follower_id])
  end
end
