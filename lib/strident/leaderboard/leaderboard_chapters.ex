defmodule Strident.Leaderboard.LeaderboardChapters do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Strident.Repo

  schema "leaderboard_chapters" do
    field :chapter_number, :integer
    has_many :seasons, Strident.Leaderboard.LeaderboardSeasons, foreign_key: :leaderboard_chapter_id

    timestamps()
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def changeset(leaderboard_chapter, attrs) do
    leaderboard_chapter
    |> cast(attrs, [:chapter_number])
    |> validate_required([:chapter_number])
  end
end
