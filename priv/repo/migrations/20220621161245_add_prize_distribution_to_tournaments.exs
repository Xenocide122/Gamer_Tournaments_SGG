defmodule Strident.Repo.Migrations.AddPrizeDistributionToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :prize_distribution, {:map, :decimal}, null: true
    end

    execute("UPDATE tournaments set prize_distribution='{}';")

    alter table(:tournaments) do
      modify :prize_distribution, {:map, :decimal}, null: false
    end
  end
end
