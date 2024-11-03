defmodule Strident.Repo.Migrations.MakeStakingStartsAtNullable do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      modify :staking_starts_at, :naive_datetime, null: true
    end
  end
end
