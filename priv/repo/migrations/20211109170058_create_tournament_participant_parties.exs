defmodule Strident.Repo.Migrations.CreateTournamentParticipantParties do
  use Ecto.Migration

  def change do
    create table(:tournament_participant_parties, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_participant_id,
          references(:tournament_participants, on_delete: :nothing, type: :binary_id),
          null: false

      add :party_id, references(:parties, on_delete: :nothing, type: :binary_id), null: false
    end

    create index(:tournament_participant_parties, [:tournament_participant_id])
    create index(:tournament_participant_parties, [:party_id])
  end
end
