defmodule Strident.Repo.Migrations.CreateBrackets do
  use Ecto.Migration

  def change do
    create table(:brackets, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id),
        null: false

      add :start_date, :date, null: false
      add :round, :integer, null: false

      timestamps()
    end

    create index(:brackets, [:tournament_id])
  end
end
