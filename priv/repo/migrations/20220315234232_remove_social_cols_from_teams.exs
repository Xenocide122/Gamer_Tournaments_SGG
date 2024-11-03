defmodule Strident.Repo.Migrations.RemoveSocialColsFromTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      remove :twitter_account
      remove :facebook_account
      remove :instagram_account
    end
  end
end
