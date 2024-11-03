defmodule Strident.Repo.Local.Migrations.UpdateTrialBalanceTable do
  use Ecto.Migration

  def change do
    alter table(:trial_balance) do
      add :metadata, :map
      add :report_title, :string
      remove :credit_balance
      remove :debit_balance
    end

    rename(table(:trial_balance), to: table(:reports))
  end
end
