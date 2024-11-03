defmodule Strident.Repo.Migrations.BackfillStageIdIntoMatches do
  use Ecto.Migration

  def up do
    alter table(:matches) do
      add :stage_id, references(:stages, on_delete: :nothing, type: :binary_id), null: true
    end

    execute(
      """
      UPDATE matches AS m SET stage_id = s.id FROM stages AS s WHERE s.tournament_id = m.tournament_id;
      """,
      """
      """
    )

    drop(constraint(:matches, "matches_stage_id_fkey"))

    alter table(:matches) do
      modify :stage_id, references(:stages, on_delete: :nothing, type: :binary_id), null: false
      remove :tournament_id
    end
  end

  def down do
    alter table(:matches) do
      add :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id),
        null: true
    end

    execute(
      """
      UPDATE matches AS m SET tournament_id = s.tournament_id FROM stages AS s WHERE s.id = m.stage_id;
      """,
      """
      """
    )

    drop(constraint(:matches, "matches_tournament_id_fkey"))

    alter table(:matches) do
      modify :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id),
        null: false

      remove :stage_id
    end
  end
end
