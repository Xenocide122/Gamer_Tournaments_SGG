defmodule Strident.Repo.Migrations.AddPrizeStrategyToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :prize_strategy, :string, null: true
    end

    execute("UPDATE tournaments set prize_strategy='prize_pool';")

    alter table(:tournaments) do
      modify :prize_strategy, :string, null: false
    end
  end
end
