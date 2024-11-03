defmodule Strident.Repo.Migrations.AddAdvancersStageEdge do
  use Ecto.Migration

  def change do
    alter table(:stage_edges) do
      add :to_advance, :integer
      add :to_advance_losers, :integer
    end
  end
end
