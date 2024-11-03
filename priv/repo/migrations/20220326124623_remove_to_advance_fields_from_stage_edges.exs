defmodule Strident.Repo.Migrations.RemoveToAdvanceFieldsFromStageEdges do
  use Ecto.Migration

  def change do
    alter table(:stage_edges) do
      remove :to_advance
      remove :to_advance_losers
    end
  end
end
