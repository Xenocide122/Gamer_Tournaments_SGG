defmodule Strident.Repo.Migrations.AddImporterFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :battlefy_profile, :string
      add :challonge_profile, :string
      add :smashgg_profile, :string
    end
  end
end
