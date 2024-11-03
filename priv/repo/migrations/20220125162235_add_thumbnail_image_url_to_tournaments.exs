defmodule Strident.Repo.Migrations.AddThumbnailImageUrlToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :thumbnail_image_url, :text
    end
  end
end
