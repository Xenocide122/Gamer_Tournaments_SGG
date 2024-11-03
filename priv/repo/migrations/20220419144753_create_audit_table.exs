defmodule Strident.Repo.Migrations.CreateAuditTable do
  use Ecto.Migration

  def change do
    create table(:audit_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string
      add :module_id, :binary_id
      add :message, :string

      timestamps()
    end
  end
end
