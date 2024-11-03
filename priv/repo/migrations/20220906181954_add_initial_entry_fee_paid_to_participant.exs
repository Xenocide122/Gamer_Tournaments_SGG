defmodule Strident.Repo.Migrations.AddInitialEntryFeePaidToParticipant do
  use Ecto.Migration

  def change do
    alter table(:tournament_participants) do
      add :initial_entry_fee_paid, :money_with_currency
    end

    execute """
    UPDATE tournament_participants AS tp SET initial_entry_fee_paid='(USD,0)';
    """

    alter table(:tournament_participants) do
      modify :initial_entry_fee_paid, :money_with_currency, null: false
    end
  end
end
