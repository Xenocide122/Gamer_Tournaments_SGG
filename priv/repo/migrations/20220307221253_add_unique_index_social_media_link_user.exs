defmodule Strident.Repo.Migrations.AddUniqueIndexSocialMediaLinkUser do
  use Ecto.Migration

  def change do
    create unique_index(:social_media_link_users, [:user_id, :social_media_link_id],
             name: :user_link_unique_idx
           )
  end
end
