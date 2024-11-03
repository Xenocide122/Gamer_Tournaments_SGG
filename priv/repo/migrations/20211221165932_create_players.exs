defmodule Strident.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false

      add :tournament_participant_id,
          references(:tournament_participants, on_delete: :nothing, type: :binary_id),
          null: false

      add :type, :string, null: true

      timestamps()
    end

    create unique_index(:players, [:user_id, :tournament_participant_id])
  end
end
