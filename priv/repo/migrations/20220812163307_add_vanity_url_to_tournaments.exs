defmodule Strident.Repo.Migrations.AddVanityUrlToTournaments do
  use Ecto.Migration

  def change do
    alter table("tournaments") do
      add :vanity_url, :text
    end

    create unique_index(:tournaments, [:vanity_url])
  end
end
