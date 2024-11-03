defmodule Strident.Repo.Migrations.CreateTournamentManagementPersonnel do
  use Ecto.Migration

  def change do
    create table("tournament_management_personnel", primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id),
        null: false

      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :role, :string

      timestamps()
    end
  end
end
