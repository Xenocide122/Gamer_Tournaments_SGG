defmodule Strident.Repo.Migrations.AddFeaturedToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :featured, :boolean, default: false
    end
  end
end
