defmodule Strident.Repo.Migrations.AddRequiredPlayerCountToTournaments do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :required_player_count, :integer, null: true
    end

    execute("update tournaments set required_player_count=1")

    alter table(:tournaments) do
      modify :required_player_count, :integer, null: false
    end
  end

  def down do
    alter table(:tournaments) do
      remove :required_player_count
    end
  end
end
