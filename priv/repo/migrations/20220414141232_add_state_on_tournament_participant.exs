defmodule Strident.Repo.Migrations.AddStatusOnTournamentParticipant do
  use Ecto.Migration

  def change do
    alter table(:tournament_participants) do
      add :status, :string
    end
  end
end
