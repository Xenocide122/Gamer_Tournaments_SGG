defmodule Strident.Repo.Migrations.AddUniqueIndexSocialMediaLinkTeam do
  use Ecto.Migration

  def change do
    create unique_index(:social_media_link_teams, [:team_id, :social_media_link_id],
             name: :link_team_unique_idx
           )
  end
end
