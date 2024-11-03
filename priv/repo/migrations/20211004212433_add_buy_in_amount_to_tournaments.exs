defmodule Strident.Repo.Migrations.AddBuyInAmountToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :buy_in_amount, :money_with_currency, null: false
    end
  end
end
