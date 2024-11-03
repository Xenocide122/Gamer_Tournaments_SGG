defmodule Strident.Repo.Migrations.CreateTiebreakerStrategies do
  use Ecto.Migration

  def change do
    create table(:tiebreaker_strategies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :stage_id, references(:stages, type: :binary_id, on_delete: :delete_all), null: false
      add :ranks_to_tiebreak, {:array, :integer}, null: false
      add :type, :string, null: false

      timestamps()
    end

    create unique_index(:tiebreaker_strategies, [:stage_id])
  end
end
