defmodule Strident.Repo.Migrations.AddPlayoffForRankToMatches do
  use Ecto.Migration

  def change do
    alter table(:matches) do
      add :playoff_for_rank, :integer, null: true
    end
  end
end
