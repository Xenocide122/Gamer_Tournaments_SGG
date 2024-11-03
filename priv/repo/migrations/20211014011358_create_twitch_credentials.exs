defmodule Strident.Repo.Migrations.CreateTwitchCredentials do
  use Ecto.Migration

  def change do
    create table(:twitch_credentials, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      add :email, :string, null: false
      add :display_name, :string, null: false
      add :twitch_id, :string, null: false
      add :login, :string, null: false
      add :profile_image_url, :string, null: false

      timestamps()
    end

    create index(:twitch_credentials, [:twitch_id])
    create index(:twitch_credentials, [:user_id])
    create unique_index(:twitch_credentials, [:email])
  end
end
