defmodule Strident.Repo.Migrations.AddCoverImageUrlToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :cover_image_url, :text
    end
  end
end
