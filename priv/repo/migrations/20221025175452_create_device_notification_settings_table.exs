defmodule Strident.Repo.Local.Migrations.CreateDeviceNotificationSettingsTable do
  use Ecto.Migration

  def change do
    create table(:device_notification_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :key, :string
      add :value, :string

      timestamps()
    end
  end
end
