defmodule Strident.Repo.Migrations.CreateSocialMediaLinkUsers do
  use Ecto.Migration

  def change do
    create table(:social_media_link_users, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :social_media_link_id,
          references(:social_media_links, on_delete: :nothing, type: :binary_id),
          null: false

      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
    end

    create index(:social_media_link_users, [:social_media_link_id])
    create index(:social_media_link_users, [:user_id])
  end
end
