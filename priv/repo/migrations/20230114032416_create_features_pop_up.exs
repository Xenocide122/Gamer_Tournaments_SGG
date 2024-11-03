defmodule Strident.Repo.Local.Migrations.CreateFeaturesPopUp do
  use Ecto.Migration

  def change do
    create table(:features, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :text)
      add(:description, :text)
      add(:image_url, :string)
      add(:blog_url, :string)
      add(:tags, {:array, :string})

      timestamps()
    end

    create table(:user_read_features, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false)

      add(:feature_id, references(:features, on_delete: :delete_all, type: :binary_id),
        null: false
      )
    end

    create(unique_index(:user_read_features, [:user_id, :feature_id]))
  end
end
