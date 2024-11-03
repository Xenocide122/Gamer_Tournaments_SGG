defmodule Strident.Repo.Migrations.AddLastEmailSentFieldTournamentInvitations do
  use Ecto.Migration

  def change do
    alter table(:tournament_invitations) do
      add :last_email_sent, :utc_datetime
    end
  end
end
