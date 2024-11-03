defmodule Strident.Repo.Migrations.CreateStageParticipants do
  use Ecto.Migration

  def change do
    create table(:stage_participants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :stage_id, references(:stages, on_delete: :nothing, type: :binary_id), null: false

      add :tournament_participant_id,
          references(:tournament_participants, on_delete: :nothing, type: :binary_id)

      add :rank, :integer

      timestamps()
    end

    create index(:stage_participants, [:tournament_participant_id])
    create index(:stage_participants, [:stage_id])

    create unique_index(:stage_participants, [:tournament_participant_id, :stage_id],
             name: :stage_participants_unique_participant_per_stage
           )
  end
end
