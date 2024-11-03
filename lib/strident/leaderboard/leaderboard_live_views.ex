defmodule Strident.Leaderboard.LeaderboardLiveViews do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "leaderboard_live_views" do
    field :tournament_name, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :interval, :integer
    field :run_count, :integer, default: 0
    field :complete, :boolean, default: false
    field :twitch_details, {:array, :map}, default: []
    field :pull_leaderboard, :boolean, default: false
    field :worker_job_id, :integer
    field :worker_running, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(leaderboard_live_view, attrs) do
    leaderboard_live_view
    |> cast(attrs, [
      :tournament_name,
      :start_time,
      :end_time,
      :interval,
      :run_count,
      :complete,
      :twitch_details,
      :pull_leaderboard,
      :worker_job_id,
      :worker_running
    ])
    |> validate_required([:tournament_name, :start_time, :end_time, :interval])
  end
end
