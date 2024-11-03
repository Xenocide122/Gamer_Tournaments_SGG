defmodule Strident.Repo.Migrations.CreateTournamentParticipants do
  use Ecto.Migration

  def change do
    create table(:tournament_participants, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id),
        null: false

      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id)
      add :party_id, references(:parties, on_delete: :nothing, type: :binary_id)

      add :rank, :integer

      timestamps()
    end

    create index(:tournament_participants, [:tournament_id])
    create index(:tournament_participants, [:team_id])
    create index(:tournament_participants, [:party_id])
  end
end
