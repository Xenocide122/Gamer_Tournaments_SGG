defmodule Strident.Repo.Migrations.AddStageSettingsToStages do
  use Ecto.Migration

  def change do
    alter table(:stages) do
      add :round, :integer
    end
  end
end
