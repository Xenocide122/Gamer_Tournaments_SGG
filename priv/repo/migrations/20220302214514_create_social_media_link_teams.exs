defmodule Strident.Repo.Migrations.CreateSocialMediaLinkTeams do
  use Ecto.Migration

  def change do
    create table(:social_media_link_teams, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :social_media_link_id,
          references(:social_media_links, on_delete: :nothing, type: :binary_id),
          null: false

      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false
    end

    create index(:social_media_link_teams, [:social_media_link_id])
    create index(:social_media_link_teams, [:team_id])
  end
end
