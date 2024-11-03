defmodule Strident.Repo.Migrations.ChangeTournamentsPrizePoolToMap do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :prize_pool_map, {:map, :money_with_currency}, null: true
    end

    execute """
    UPDATE tournaments SET prize_pool_map='{"0": {"currency_code":"USD","amount":0}, "1": {"currency_code":"USD","amount":0}, "2": {"currency_code":"USD","amount":0}}'
    """

    execute """
    UPDATE tournaments SET prize_pool_map=jsonb_set(prize_pool_map, '{0}', to_jsonb(prize_pool))
    """

    alter table(:tournaments) do
      modify :prize_pool_map, {:map, :money_with_currency}, null: false
      remove :prize_pool
    end

    rename table(:tournaments), :prize_pool_map, to: :prize_pool
  end
end
