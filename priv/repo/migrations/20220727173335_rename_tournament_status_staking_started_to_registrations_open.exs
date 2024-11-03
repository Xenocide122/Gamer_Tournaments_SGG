defmodule Strident.Repo.Migrations.RenameTournamentStatusStakingStartedToRegistrationsOpen do
  use Ecto.Migration

  def change do
    up = "UPDATE tournaments set status='registrations_open' where status='staking_started';"
    down = "UPDATE tournaments set status='staking_started' where status='registrations_open';"
    execute(up, down)
  end
end
