defmodule Strident.Repo.Local.Migrations.AddStatusTrailBalance do
  use Ecto.Migration

  def change do
    alter table(:trial_balance) do
      add :status, :string, null: false
    end
  end
end
