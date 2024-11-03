defmodule Strident.Repo.Local.Migrations.CreateNotificationTable do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :level, :string
      add :data, :map
      add :is_unread, :boolean, default: true
      add :deleted_at, :utc_datetime

      timestamps()
    end
  end
end
