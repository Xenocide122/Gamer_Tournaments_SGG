defmodule Strident.Repo.Migrations.CreateStages do
  use Ecto.Migration

  def change do
    create table(:stages, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id),
        null: false

      add :type, :string, null: false

      timestamps()
    end

    create index(:stages, [:tournament_id])
  end
end
