defmodule Strident.Repo.Migrations.AddGameSlug do
  use Ecto.Migration

  def up do
    alter table(:games) do
      add :slug, :string, null: true
    end

    execute("""
    	UPDATE games
    	SET slug = REGEXP_REPLACE(LOWER(title), '\\W+', '-', 'g');
    """)

    alter table("games") do
      modify :slug, :string, null: false
    end

    create unique_index(:games, [:slug])
  end

  def down do
    alter table(:games) do
      remove :slug
    end
  end
end
