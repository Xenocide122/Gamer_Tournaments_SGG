defmodule Strident.Repo.Migrations.CreateTournamentParticipantTeams do
  use Ecto.Migration

  def change do
    create table(:tournament_participant_teams, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_participant_id,
          references(:tournament_participants, on_delete: :nothing, type: :binary_id),
          null: false

      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false
    end

    create index(:tournament_participant_teams, [:tournament_participant_id])
    create index(:tournament_participant_teams, [:team_id])
  end
end
