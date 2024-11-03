defmodule Strident.Repo.Migrations.RemoveSocialColsFromPros do
  use Ecto.Migration

  def change do
    alter table(:pros) do
      remove :twitch_handle
      remove :twitch_channel
      remove :twitter_account
      remove :facebook_account
      remove :instagram_account
      remove :discord_account
    end
  end
end
