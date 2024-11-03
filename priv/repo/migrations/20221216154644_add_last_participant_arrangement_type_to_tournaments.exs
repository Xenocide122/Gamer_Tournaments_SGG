defmodule Strident.Repo.Local.Migrations.AddLastParticipantArrangementTypeToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :last_participant_arrangement_type, :string, null: true
    end
  end
end
