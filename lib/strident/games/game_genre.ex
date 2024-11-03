defmodule Strident.Games.GameGenre do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias Strident.Games.Game
  alias Strident.Games.Genre

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "game_genres" do
    belongs_to(:genre, Genre)
    belongs_to(:game, Game)
  end

  @doc false
  def changeset(game_genre, attrs) do
    game_genre
    |> bulk_update_changeset(attrs)
    |> unsafe_validate_unique([:genre_id, :game_id], Strident.Repo)
  end

  @doc false
  def bulk_update_changeset(game_genre, attrs) do
    game_genre
    |> cast(attrs, [:genre_id, :game_id])
    |> validate_required([:genre_id, :game_id])
    |> foreign_key_constraint(:genre_id)
    |> foreign_key_constraint(:game_id)
  end

  @doc false
  def game_assoc_changeset(game_genre, attrs) do
    game_genre
    |> cast(attrs, [:genre_id])
    |> validate_required([:genre_id])
    |> foreign_key_constraint(:genre_id)
  end
end
