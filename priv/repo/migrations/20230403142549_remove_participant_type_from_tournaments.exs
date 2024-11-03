defmodule Strident.Repo.Local.Migrations.RemoveParticipantTypeFromTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      remove :participant_type
    end
  end
end
