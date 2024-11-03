defmodule Strident.Repo.Migrations.AddProfileBannerToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :banner_url, :string, null: true
    end
  end
end
