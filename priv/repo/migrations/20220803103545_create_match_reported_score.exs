defmodule Strident.Repo.Migrations.CreateMatchReportedScore do
  use Ecto.Migration

  def change do
    create table(:match_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :match_id,
          references(:matches, on_delete: :nothing, type: :binary_id),
          null: false

      add :match_participant_id,
          references(:match_participants, on_delete: :nothing, type: :binary_id),
          null: false

      add :reported_score, :map
      timestamps()
    end
  end
end
