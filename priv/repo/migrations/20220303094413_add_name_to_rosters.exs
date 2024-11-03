defmodule Strident.Repo.Migrations.AddNameToRosters do
  use Ecto.Migration

  def up do
    alter table(:team_rosters) do
      add :name, :string, null: true
      add :slug, :string, null: true
    end

    execute("""
    UPDATE team_rosters AS r
    SET name = g.title || ' Team'
    FROM games g
    WHERE r.game_id = g.id;
    """)

    execute("""
    UPDATE team_rosters
    	SET slug = REGEXP_REPLACE(LOWER(name), '\\W+', '-', 'g');
    """)

    alter table(:team_rosters) do
      modify :slug, :string, null: false
      modify :name, :string, null: false
    end

    create unique_index(:team_rosters, [:team_id, :slug])
  end

  def down do
    alter table(:team_rosters) do
      remove :name
      remove :slug
    end
  end
end
