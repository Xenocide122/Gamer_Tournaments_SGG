defmodule Strident.Repo.Migrations.AddTwitchChannelToTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :twitch_channel, :string
    end
  end
end
