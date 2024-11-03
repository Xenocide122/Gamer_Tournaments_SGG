defmodule Strident.Repo.Migrations.AddPrizePoolToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :prize_pool, :money_with_currency, null: false
    end
  end
end
