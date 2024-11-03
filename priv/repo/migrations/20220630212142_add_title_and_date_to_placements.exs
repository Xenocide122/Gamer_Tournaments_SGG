defmodule Strident.Repo.Migrations.AddTitleAndDateToPlacements do
  use Ecto.Migration

  def change do
    alter table(:placements) do
      add :title, :string
      add :date, :naive_datetime
      add :game_title, :string
    end
  end
end
