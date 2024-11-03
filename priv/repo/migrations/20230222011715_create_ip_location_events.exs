defmodule Strident.Repo.Local.Migrations.CreateIpLocationEvents do
  use Ecto.Migration

  def change do
    create table(:ip_location_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :remote_ip, :string, null: false
      add :region_code, :string, null: false
      add :country_code, :string, null: false

      timestamps(updated_at: false)
    end

    create index(:ip_location_events, [:user_id])
    create index(:ip_location_events, [:remote_ip])
    create index(:ip_location_events, [:region_code])
    create index(:ip_location_events, [:country_code])
  end
end
