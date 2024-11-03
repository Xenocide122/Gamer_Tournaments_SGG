defmodule Strident.Repo.Local.Migrations.CreateAppleCredentials do
  use Ecto.Migration

  def change do
    create table(:apple_credentials, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      add :email, :string, null: true
      add :apple_id, :string, null: false
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create index(:apple_credentials, [:user_id])
    create index(:apple_credentials, [:apple_id])
  end
end
