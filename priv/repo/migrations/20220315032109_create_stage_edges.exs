defmodule Strident.Repo.Migrations.CreateStageEdges do
  use Ecto.Migration

  def change do
    create table(:stage_edges, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :parent_id, references(:stages, on_delete: :nothing, type: :binary_id), null: false
      add :child_id, references(:stages, on_delete: :nothing, type: :binary_id), null: false
    end

    create unique_index(:stage_edges, [:child_id, :parent_id])
    create index(:stage_edges, [:parent_id])
    create index(:stage_edges, [:child_id])
  end
end
