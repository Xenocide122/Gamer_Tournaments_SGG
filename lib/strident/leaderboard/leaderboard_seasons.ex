defmodule Strident.Leaderboard.LeaderboardSeasons do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "leaderboard_seasons" do
    field :season_number, :integer
    field :start_date, :naive_datetime
    field :end_date, :naive_datetime

    belongs_to :chapter, Strident.Leaderboard.LeaderboardChapters,
      foreign_key: :leaderboard_chapter_id,
      on_replace: :update

    timestamps()
  end

  def changeset(leaderboard_season, attrs) do
    leaderboard_season
    |> cast(attrs, [:season_number, :start_date, :end_date, :leaderboard_chapter_id])
    |> validate_required([:season_number, :start_date, :end_date, :leaderboard_chapter_id])
    |> unique_constraint([:leaderboard_chapter_id, :season_number])
  end
end
