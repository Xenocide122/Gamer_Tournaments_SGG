defmodule Strident.Repo.Migrations.AddStakingStartsAtOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :staking_starts_at, :naive_datetime, null: true
    end

    execute """
    UPDATE tournaments AS t SET staking_starts_at=t.starts_at
    """

    alter table(:tournaments) do
      modify :staking_starts_at, :naive_datetime, null: false
    end
  end
end
