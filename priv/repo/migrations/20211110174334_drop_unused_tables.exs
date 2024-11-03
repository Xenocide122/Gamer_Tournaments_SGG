defmodule Strident.Repo.Migrations.DropUnusedTables do
  use Ecto.Migration

  def change do
    drop table(:bracket_participant_teams)
    drop table(:bracket_participant_parties)
  end
end
