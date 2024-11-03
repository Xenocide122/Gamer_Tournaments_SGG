defmodule Strident.Repo.Migrations.CreateTeamSocialHandles do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :twitter_account, :string
      add :facebook_account, :string
      add :instagram_account, :string
    end
  end
end
