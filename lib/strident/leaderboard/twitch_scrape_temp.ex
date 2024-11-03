defmodule Strident.Leaderboard.TwitchScrapeTemp do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "twitch_scrape_temp" do
    field :display_name, :string
    field :viewer_count, :integer
    field :title, :string
    field :preview_link, :string
    field :pulled_at, :utc_datetime

    belongs_to :leaderboard_live_views, Strident.Leaderboard.LeaderboardLiveViews

    timestamps()
  end

  @doc false
  def changeset(twitch_scrape_temp, attrs) do
    twitch_scrape_temp
    |> cast(attrs, [:leaderboard_live_views_id, :display_name, :viewer_count, :title, :preview_link, :pulled_at])
    |> validate_required([:leaderboard_live_views_id, :display_name, :viewer_count, :title, :preview_link, :pulled_at])
  end
end
