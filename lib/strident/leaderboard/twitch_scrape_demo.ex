defmodule Strident.Leaderboard.TwitchScrapeDemo do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "twitch_scrape_demo" do
    field :display_name, :string
    field :viewer_count, :integer
    field :title, :string
    field :preview_link, :string
    field :pulled_at, :utc_datetime

    belongs_to :demo_live_views, Strident.Leaderboard.DemoLiveViews

    timestamps()
  end

  @doc false
  def changeset(twitch_scrape_demo, attrs) do
    twitch_scrape_demo
    |> cast(attrs, [:demo_live_views_id, :display_name, :viewer_count, :title, :preview_link, :pulled_at])
    |> validate_required([:demo_live_views_id, :display_name, :viewer_count, :title, :preview_link, :pulled_at])
    |> foreign_key_constraint(:demo_live_views_id)
  end
end
