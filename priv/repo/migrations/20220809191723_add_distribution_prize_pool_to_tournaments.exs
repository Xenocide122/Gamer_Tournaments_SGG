defmodule Strident.Repo.Migrations.AddDistributionPrizePoolToTournaments do
  use Ecto.Migration

  def change do
    alter table("tournaments") do
      add :distribution_prize_pool, {:map, :money_with_currency}
    end

    execute "UPDATE tournaments SET distribution_prize_pool='{}'"

    alter table(:tournaments) do
      modify :distribution_prize_pool, {:map, :money_with_currency},
        null: false,
        from: {:map, :money_with_currency}
    end
  end
end
