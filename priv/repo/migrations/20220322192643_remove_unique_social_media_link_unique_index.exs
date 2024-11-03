defmodule Strident.Repo.Migrations.RemoveUniqueSocialMediaLinkUniqueIndex do
  use Ecto.Migration

  def change do
    drop_if_exists index(:social_media_links, [:handle, :brand], name: :handle_brand_unique_idx)
  end
end
