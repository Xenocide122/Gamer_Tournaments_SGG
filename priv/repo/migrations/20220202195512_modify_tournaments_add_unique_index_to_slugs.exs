defmodule Strident.Repo.Migrations.ModifyTournamentsAddUniqueIndexToSlugs do
  use Ecto.Migration

  def change do
    alter table("tournaments") do
      modify :slug, :string, null: false
    end

    create unique_index(:tournaments, [:slug])
  end
end
