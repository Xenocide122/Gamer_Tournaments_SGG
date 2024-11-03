defmodule Strident.Repo.Migrations.CascadeDeleteSocialMediaLinkUsers do
  use Ecto.Migration

  def up do
    drop(
      constraint(
        :social_media_link_users,
        "social_media_link_users_social_media_link_id_fkey"
      )
    )

    alter table(:social_media_link_users) do
      modify :social_media_link_id,
             references(:social_media_links, on_delete: :delete_all, type: :binary_id),
             null: false
    end
  end

  def down do
    drop(
      constraint(
        :social_media_link_users,
        "social_media_link_users_social_media_link_id_fkey"
      )
    )

    alter table(:social_media_link_users) do
      modify :social_media_link_id,
             references(:social_media_links, on_delete: :nothing, type: :binary_id),
             null: false
    end
  end
end
