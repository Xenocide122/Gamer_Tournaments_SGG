defmodule Strident.Repo.Migrations.AddSocialLinksToPro do
  use Ecto.Migration

  def change do
    alter table(:pros) do
      add :twitter_account, :string
      add :facebook_account, :string
      add :instagram_account, :string
    end
  end
end
