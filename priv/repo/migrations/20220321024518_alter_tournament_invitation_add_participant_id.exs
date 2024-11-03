defmodule Strident.Repo.Migrations.AlterTournamentInvitationAddParticipantId do
  use Ecto.Migration

  def change do
    alter table(:tournament_invitations) do
      add :tournament_participant_id,
          references(:tournament_participants, type: :binary_id, on_delete: :delete_all),
          null: true
    end
  end
end
