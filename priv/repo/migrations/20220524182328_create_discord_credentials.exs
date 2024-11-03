defmodule Strident.Repo.Migrations.CreateDiscordCredentials do
  use Ecto.Migration

  def change do
    create table(:discord_credentials, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      add :email, :string, null: false
      add :display_name, :string, null: false
      add :discord_id, :string, null: false
      add :login, :string, null: false
      add :profile_image_url, :string, null: false

      timestamps()
    end

    create index(:discord_credentials, [:user_id])
    create index(:discord_credentials, [:discord_id])
    create unique_index(:discord_credentials, [:email])
  end
end
