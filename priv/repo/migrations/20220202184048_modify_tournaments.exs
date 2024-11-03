defmodule Strident.Repo.Migrations.ModifyTournaments do
  use Ecto.Migration

  def change do
    alter table("tournaments") do
      add :slug, :string, default: "", null: false
    end
  end
end
