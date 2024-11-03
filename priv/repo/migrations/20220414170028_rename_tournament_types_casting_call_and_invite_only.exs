defmodule Strident.Repo.Migrations.RenameTournamentTypesCastingCallAndInviteOnly do
  use Ecto.Migration

  def up do
    execute("UPDATE tournaments set type = 'casting_call' where type = 'open';")
    execute("UPDATE tournaments set type = 'invite_only' where type = 'curated';")
  end

  def down do
    execute("UPDATE tournaments set type = 'open' where type = 'casting_call' ;")
    execute("UPDATE tournaments set type =  'curated' where type = 'invite_only' ;")
  end
end
