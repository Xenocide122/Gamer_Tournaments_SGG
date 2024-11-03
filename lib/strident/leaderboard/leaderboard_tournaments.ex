defmodule Strident.Leaderboard.LeaderboardTournaments do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "leaderboard_tournaments" do
    field :name, :string
    field :start, :naive_datetime
    field :end, :naive_datetime
    field :team_size, :integer
    field :url_id, Ecto.UUID

    belongs_to :season, Strident.Leaderboard.LeaderboardSeasons,
      foreign_key: :leaderboard_season_id,
      on_replace: :update

    timestamps()
  end

  def changeset(leaderboard_tournament, attrs) do
    leaderboard_tournament
    |> cast(attrs, [:name, :start, :end, :team_size, :url_id, :leaderboard_season_id])
    |> validate_required([:name, :start, :end, :url_id, :leaderboard_season_id])
    |> unique_constraint(:url_id)
  end
end
