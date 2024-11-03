defmodule Strident.Repo.Local.Migrations.AlterReportsAddReportsTitle do
  use Ecto.Migration

  def change do
    execute """
      ALTER TABLE reports ADD COLUMN IF NOT EXISTS report_title VARCHAR(255)
    """

    execute """
      ALTER TABLE reports DROP COLUMN IF EXISTS report_name
    """
  end
end
