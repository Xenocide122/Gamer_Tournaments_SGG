defmodule Strident.Repo.Migrations.AddStatusToTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :status, :string, null: true
    end

    execute """
    UPDATE tournaments SET status='scheduled'
    """

    alter table(:tournaments) do
      modify :status, :string, null: false
    end
  end
end
