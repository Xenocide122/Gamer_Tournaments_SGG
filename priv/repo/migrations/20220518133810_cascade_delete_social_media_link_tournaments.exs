defmodule Strident.Repo.Migrations.CascadeDeleteSocialMediaLinkTournaments do
  use Ecto.Migration

  def up do
    drop(
      constraint(
        :social_media_link_tournaments,
        "social_media_link_tournaments_social_media_link_id_fkey"
      )
    )

    alter table(:social_media_link_tournaments) do
      modify :social_media_link_id,
             references(:social_media_links, on_delete: :delete_all, type: :binary_id),
             null: false
    end
  end

  def down do
    drop(
      constraint(
        :social_media_link_tournaments,
        "social_media_link_tournaments_social_media_link_id_fkey"
      )
    )

    alter table(:social_media_link_tournaments) do
      modify :social_media_link_id,
             references(:social_media_links, on_delete: :nothing, type: :binary_id),
             null: false
    end
  end
end
