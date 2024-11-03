defmodule Strident.Repo.Migrations.RenameStakingStartsAtToRegistrationsOpenAt do
  use Ecto.Migration

  def change do
    rename table(:tournaments), :staking_starts_at, to: :registrations_open_at
  end
end
