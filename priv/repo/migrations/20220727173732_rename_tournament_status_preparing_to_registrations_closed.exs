defmodule Strident.Repo.Migrations.RenameTournamentStatusPreparingToRegistrationsClosed do
  use Ecto.Migration

  def change do
    up = "UPDATE tournaments set status='registrations_closed' where status='preparing';"
    down = "UPDATE tournaments set status='preparing' where status='registrations_closed';"
    execute(up, down)
  end
end
