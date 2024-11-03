defmodule Strident.Repo.Local.Migrations.AddDateToReports do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      add :reports_for, :date
    end
  end
end
