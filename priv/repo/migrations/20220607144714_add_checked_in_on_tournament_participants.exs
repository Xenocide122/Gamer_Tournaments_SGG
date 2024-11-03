defmodule Strident.Repo.Migrations.AddCheckedInOnTournamentParticipants do
  use Ecto.Migration

  def change do
    alter table(:tournament_participants) do
      add :checked_in, :boolean, default: false
    end
  end
end
