defmodule Strident.Repo.Migrations.AddUniqueIndexSocialMediaLink do
  use Ecto.Migration

  def change do
    create unique_index(:social_media_links, [:handle, :brand], name: :handle_brand_unique_idx)
  end
end
