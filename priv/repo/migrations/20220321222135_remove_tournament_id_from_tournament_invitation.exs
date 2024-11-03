defmodule Strident.Repo.Migrations.RemoveTournamentIdFromTournamentInvitation do
  use Ecto.Migration

  def change do
    alter table(:tournament_invitations) do
      remove :tournament_id
    end
  end
end
