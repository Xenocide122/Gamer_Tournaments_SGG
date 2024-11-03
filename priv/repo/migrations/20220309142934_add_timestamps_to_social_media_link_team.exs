defmodule Strident.Repo.Migrations.AddTimestampsToSocialMediaLinkTeam do
  use Ecto.Migration

  def change do
    alter table(:social_media_link_teams) do
      timestamps default: fragment("now()"), null: false
    end
  end
end
