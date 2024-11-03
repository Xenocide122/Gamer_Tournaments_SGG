defmodule Strident.Repo.Migrations.UniqueConstraintTournamentInvitation do
  use Ecto.Migration

  def change do
    drop_if_exists index(
                     :tournament_invitations,
                     [:tournament_participant_id],
                     name: :participant_status_unique_index
                   )

    create unique_index(
             :tournament_invitations,
             [:tournament_participant_id],
             name: :participant_status_unique_index,
             where: "status in ('pending', 'accepted')"
           )
  end
end
