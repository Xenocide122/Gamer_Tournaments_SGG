defmodule Strident.Repo.Migrations.CreateChangelogs do
  use Ecto.Migration

  def change do
    create table(:changelogs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :published_at, :naive_datetime
      add :title, :text
      add :body, :text
      add :slug, :text

      timestamps()
    end
  end
end
