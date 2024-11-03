defmodule Strident.Repo.Migrations.RemoveSlugFromPros do
  use Ecto.Migration

  def change do
    alter table(:pros) do
      remove :slug
    end
  end
end
