defmodule Strident.Repo.Migrations.AllowMultipleTiebreakStrategies do
  use Ecto.Migration

  def up do
    alter table(:tiebreaker_strategies) do
      remove :type
      add :type, {:array, :string}, null: true
    end

    execute("UPDATE tiebreaker_strategies SET type = '{}';")

    alter table(:tiebreaker_strategies) do
      modify :type, {:array, :string}, null: false
    end
  end

  def down do
    alter table(:tiebreaker_strategies) do
      remove :type
      add :type, :string, null: false
    end
  end
end
