defmodule Strident.Repo.Migrations.AddSeedIndexToTournamentParticipants do
  use Ecto.Migration

  def change do
    alter table(:tournament_participants) do
      add :seed_index, :integer
    end
  end
end
