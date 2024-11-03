defmodule Strident.Repo.Migrations.AddUniqueIndexToSlugOnUsers do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:slug])
  end
end
