defmodule Strident.Repo.Migrations.CreateTournamentStatLabels do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :stat_labels, {:array, :string}, null: true
    end
  end
end
