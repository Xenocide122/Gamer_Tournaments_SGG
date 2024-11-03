defmodule Strident.Repo.Migrations.CreateSocialMediaLinkTournaments do
  use Ecto.Migration

  def change do
    create table(:social_media_link_tournaments, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :social_media_link_id,
          references(:social_media_links, on_delete: :nothing, type: :binary_id),
          null: false

      add :tournament_id, references(:tournaments, on_delete: :nothing, type: :binary_id),
        null: false

      timestamps()
    end

    create index(:social_media_link_tournaments, [:social_media_link_id])
    create index(:social_media_link_tournaments, [:tournament_id])

    create unique_index(:social_media_link_tournaments, [:tournament_id, :social_media_link_id],
             name: :link_tournament_unique_idx
           )
  end
end
