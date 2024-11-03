defmodule Strident.Repo.Migrations.AddOpenContributionFieldsToTournamentParticipant do
  use Ecto.Migration

  def change do
    alter table(:tournament_participants) do
      add :initial_open_contribution_amount, :money_with_currency
      add :current_open_contribution_amount, :money_with_currency
    end
  end
end
