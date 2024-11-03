defmodule Strident.Repo.Migrations.AddRequiredParticipantCountToTournaments do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :required_participant_count, :integer
    end
  end

  def down do
    alter table(:tournaments) do
      remove :required_participant_count
    end
  end
end
