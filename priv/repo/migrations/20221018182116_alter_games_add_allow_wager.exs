defmodule Strident.Repo.Migrations.AlterGamesAddAllowWager do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :allow_wager, :boolean, default: false
    end
  end
end
