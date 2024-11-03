defmodule Strident.Repo.Migrations.AddUniqueIndexToSlugOnTeams do
  use Ecto.Migration

  def change do
    create unique_index(:teams, [:slug])
  end
end
