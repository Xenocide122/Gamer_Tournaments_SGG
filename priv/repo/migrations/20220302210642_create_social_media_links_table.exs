defmodule Strident.Repo.Migrations.CreateSocialMediaLinksTable do
  use Ecto.Migration

  def change do
    create table(:social_media_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :handle, :string, null: false
      add :brand, :string, null: false
      add :description, :string
      add :hidden, :boolean, default: false

      timestamps()
    end
  end
end
