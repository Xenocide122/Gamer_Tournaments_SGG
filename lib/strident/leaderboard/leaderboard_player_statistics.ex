defmodule Strident.Leaderboard.LeaderboardPlayerStatistics do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "leaderboard_player_statistics" do
    field :score, :integer
    field :games, :integer
    field :eliminations, :integer
    field :wins, :integer
    belongs_to :tournament, Strident.Leaderboard.LeaderboardTournaments, foreign_key: :leaderboard_tournament_id
    belongs_to :player, Strident.Leaderboard.LeaderboardPlayers, foreign_key: :leaderboard_player_id

    timestamps()
  end

  def changeset(leaderboard_player_statistic, attrs) do
    leaderboard_player_statistic
    |> cast(attrs, [:score, :games, :eliminations, :wins, :leaderboard_tournament_id, :leaderboard_player_id])
    |> validate_required([:score, :games, :eliminations, :wins, :leaderboard_tournament_id, :leaderboard_player_id])
  end
end
