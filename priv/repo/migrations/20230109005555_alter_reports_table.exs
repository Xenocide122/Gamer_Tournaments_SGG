defmodule Strident.Repo.Local.Migrations.AlterReportsTable do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      add :report_type, :string
    end

    rename table(:reports), :reports_for, to: :report_for_date
  end
end
