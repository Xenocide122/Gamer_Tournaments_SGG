defmodule Strident.Repo.Migrations.UpdateSchemasWithTournamentParticipants do
  use Ecto.Migration

  def change do
    alter table(:bracket_participants) do
      add :tournament_participant_id,
          references(:tournament_participants, on_delete: :nothing, type: :binary_id)
    end
  end
end
