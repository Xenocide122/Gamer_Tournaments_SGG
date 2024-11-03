defmodule Strident.Repo.Migrations.FixTournamentsPrizeStrategy do
  use Ecto.Migration

  def change do
    execute "UPDATE tournaments set prize_strategy='Fixed Amount Prizes' where prize_strategy='prize_pool';"

    execute "UPDATE tournaments set prize_strategy='Percentage Based Prizes' where prize_strategy='prize_distribution';"
  end
end
