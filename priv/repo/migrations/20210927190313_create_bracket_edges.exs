defmodule Strident.Repo.Migrations.CreateBracketEdges do
  use Ecto.Migration

  def change do
    create table(:bracket_edges, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :parent_id, references(:brackets, on_delete: :nothing, type: :binary_id), null: false
      add :child_id, references(:brackets, on_delete: :nothing, type: :binary_id), null: false
    end

    create unique_index(:bracket_edges, [:child_id, :parent_id])
    create index(:bracket_edges, [:parent_id])
    create index(:bracket_edges, [:child_id])
  end
end
