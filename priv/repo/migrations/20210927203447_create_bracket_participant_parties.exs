defmodule Strident.Repo.Migrations.CreateBracketParticipantParties do
  use Ecto.Migration

  def change do
    create table(:bracket_participant_parties, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :bracket_participant_id,
          references(:bracket_participants, on_delete: :nothing, type: :binary_id),
          null: false

      add :party_id, references(:parties, on_delete: :nothing, type: :binary_id), null: false
    end

    create index(:bracket_participant_parties, [:bracket_participant_id])
    create index(:bracket_participant_parties, [:party_id])
  end
end
