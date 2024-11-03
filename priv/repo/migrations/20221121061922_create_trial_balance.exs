defmodule Strident.Repo.Local.Migrations.CreateTrialBalance do
  use Ecto.Migration

  def change do
    create table(:trial_balance, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :debit_balance, :money_with_currency
      add :credit_balance, :money_with_currency

      timestamps()
    end
  end
end
