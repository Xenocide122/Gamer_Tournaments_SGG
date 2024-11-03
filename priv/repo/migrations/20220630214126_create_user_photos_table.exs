defmodule Strident.Repo.Migrations.CreateUserPhotosTable do
  use Ecto.Migration

  def change do
    create table(:user_photos, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :photo_id,
          references(:photos, on_delete: :nothing, type: :binary_id),
          null: false

      add :user_id,
          references(:users, on_delete: :nothing, type: :binary_id),
          null: false
    end
  end
end
