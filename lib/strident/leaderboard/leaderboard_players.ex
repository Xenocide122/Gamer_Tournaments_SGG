defmodule Strident.Leaderboard.LeaderboardPlayers do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "leaderboard_players" do
    field :name, :string
    field :avatar, :string
    field :discord_id, :string
    field :epic_id, :string
    timestamps()
  end

  def changeset(leaderboard_player, attrs) do
    leaderboard_player
    |> cast(attrs, [:name, :avatar, :discord_id, :epic_id])
    |> validate_required(:name)
    |> unique_constraint(:discord_id)
    |> unique_constraint(:epic_id)
  end
end
