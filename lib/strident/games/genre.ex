defmodule Strident.Games.Genre do
  @moduledoc """
  A genre for a game
  """

  use TypedEctoSchema

  import Ecto.Changeset

  alias Strident.Games.GameGenre

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "genres" do
    field(:genre_name, :string)
    field(:slug, :string)
    field(:hidden, :boolean)
    field(:feature, :boolean)

    has_many(:genre_games, GameGenre)
    has_many(:games, through: [:genre_games, :game])
  end

  @doc false
  def changeset(genre, attrs) do
    genre
    |> cast(attrs, [:genre_name, :slug, :hidden, :feature])
    |> validate_required([:genre_name])
    |> add_slug()
    |> unique_constraint(:slug, name: "genres_slug_index")
    |> validate_required([:slug])
  end

  def add_slug(changeset) do
    case get_change(changeset, :genre_name) do
      genre_name when is_binary(genre_name) ->
        put_change(changeset, :slug, Slug.slugify(genre_name))

      _ ->
        changeset
    end
  end
end
