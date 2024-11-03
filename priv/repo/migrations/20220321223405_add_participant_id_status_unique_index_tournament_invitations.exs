defmodule Strident.Repo.Migrations.AddParticipantIdStatusUniqueIndexTournamentInvitations do
  use Ecto.Migration

  def change do
    create unique_index(
             :tournament_invitations,
             [:tournament_participant_id, :status],
             name: :participant_status_unique_index,
             where: "status in ('pending', 'accepted')"
           )
  end
end
