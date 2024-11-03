defmodule Strident.Repo.Migrations.CreateFeaturedTeamJoinTable do
  use Ecto.Migration

  def change do
    create table(:team_user_feature) do
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id),
        null: false,
        primary_key: true
    end
  end
end
