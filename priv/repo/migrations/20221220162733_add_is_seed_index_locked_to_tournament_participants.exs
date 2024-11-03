defmodule Strident.Repo.Local.Migrations.AddIsSeedIndexLockedToTournamentParticipants do
  use Ecto.Migration

  def change do
    alter table(:tournament_participants) do
      add :is_seed_index_locked, :boolean
    end
  end
end
