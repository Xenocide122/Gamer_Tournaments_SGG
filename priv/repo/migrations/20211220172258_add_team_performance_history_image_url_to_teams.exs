defmodule Strident.Repo.Migrations.AddTeamPerformanceHistoryImageUrlToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :team_performance_history_image_url, :string
    end
  end
end
