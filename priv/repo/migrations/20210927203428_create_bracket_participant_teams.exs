defmodule Strident.Repo.Migrations.CreateBracketParticipantTeams do
  use Ecto.Migration

  def change do
    create table(:bracket_participant_teams, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :bracket_participant_id,
          references(:bracket_participants, on_delete: :nothing, type: :binary_id),
          null: false

      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false
    end

    create index(:bracket_participant_teams, [:bracket_participant_id])
    create index(:bracket_participant_teams, [:team_id])
  end
end
