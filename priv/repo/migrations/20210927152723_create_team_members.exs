defmodule Strident.Repo.Migrations.CreateTeamMembers do
  use Ecto.Migration

  def change do
    create table(:team_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:team_members, [:user_id, :team_id])
  end
end
