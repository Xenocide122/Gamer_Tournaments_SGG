defmodule Strident.Repo.Migrations.AddStakingAllowedToTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :allow_staking, :boolean, default: false
    end
  end
end
