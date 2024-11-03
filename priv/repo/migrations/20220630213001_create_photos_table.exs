defmodule Strident.Repo.Migrations.CreatePhotosTable do
  use Ecto.Migration

  def change do
    create table(:photos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :link, :string
      add :name, :string
      add :public, :boolean, default: true

      timestamps()
    end
  end
end
