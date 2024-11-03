defmodule Strident.Repo.Migrations.CascadeDeleteUserPhotos do
  use Ecto.Migration

  def up do
    drop(constraint(:user_photos, "user_photos_photo_id_fkey"))

    alter table(:user_photos) do
      modify(:photo_id, references(:photos, on_delete: :delete_all, type: :binary_id), null: false)
    end
  end

  def down do
    drop(constraint(:user_photos, "user_photos_photo_id_fkey"))

    alter table(:user_photos) do
      modify(:photo_id, references(:photos, on_delete: :nothing, type: :binary_id), null: false)
    end
  end
end
