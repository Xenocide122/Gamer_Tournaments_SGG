defmodule Strident.Repo.Local.Migrations.CreateDiscordConnections do
  use Ecto.Migration

  def change do
    create table(:discord_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :discord_credential_id,
          references(:discord_credentials,
            type: :binary_id,
            on_delete: :delete_all,
            column: :user_id
          ),
          null: false

      add :discord_id, :string, null: false
      add :name, :string, null: false
      add :type, :string, null: false
      add :is_visible, :boolean, null: false
      add :is_verified, :boolean, null: false
      add :is_revoked, :boolean, null: false

      timestamps()
    end

    create index(:discord_connections, [:discord_credential_id])
    create index(:discord_connections, [:discord_id])
  end
end
