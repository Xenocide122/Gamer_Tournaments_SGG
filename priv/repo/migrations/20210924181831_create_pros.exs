defmodule Strident.Repo.Migrations.CreatePros do
  use Ecto.Migration

  def change do
    create table(:pros, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :twitch_channel, :string
      add :twitch_handle, :string, null: false
      add :bio, :text, null: false
      add :avatar_url, :string
      add :verified, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:pros, [:name])
    create unique_index(:pros, [:twitch_handle])
  end
end
