defmodule Strident.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :text
      add :description, :text
      add :cover_image_url, :text

      timestamps()
    end
  end
end
