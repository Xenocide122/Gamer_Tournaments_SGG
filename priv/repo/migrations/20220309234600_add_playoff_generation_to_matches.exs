defmodule Strident.Repo.Migrations.AddPlayoffGenerationToMatches do
  use Ecto.Migration

  def change do
    alter table(:matches) do
      add :playoff_generation, :integer, null: true
    end
  end
end
