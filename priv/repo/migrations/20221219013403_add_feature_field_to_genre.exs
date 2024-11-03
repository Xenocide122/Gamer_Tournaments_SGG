defmodule Strident.Repo.Local.Migrations.AddFeatureFieldToGenre do
  use Ecto.Migration

  def change do
    alter table(:genres) do
      add :feature, :boolean, default: false
    end
  end
end
