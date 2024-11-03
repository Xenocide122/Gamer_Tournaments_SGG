defmodule Strident.Repo.Migrations.AddStatusToStages do
  use Ecto.Migration

  def change do
    alter table(:stages) do
      add :status, :string, null: true
    end

    execute """
    UPDATE stages SET status='scheduled'
    """

    alter table(:stages) do
      modify :status, :string, null: false
    end
  end
end
