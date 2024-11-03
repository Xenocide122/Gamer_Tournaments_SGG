defmodule Strident.Repo.Migrations.MakePlacementsSchemaExternalOnly do
  use Ecto.Migration

  def change do
    alter table(:placements) do
      remove :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id)
      remove :is_external, :boolean, default: false, null: false
    end
  end
end
