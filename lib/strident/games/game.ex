defmodule Strident.Games.Game do
  @moduledoc """
  A video game, with an association to TeamRosters.
  """
  use TypedEctoSchema

  import Ecto.Changeset

  alias Strident.Games.GameGenre
  alias Strident.Teams.TeamRoster

  @type id :: Strident.id()

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "games" do
    field(:cover_image_url, :string)
    field(:default_game_banner_url, :string)
    field(:logo_url, :string)
    field(:short_logo, :string)
    field(:description, :string)
    field(:title, :string)
    field(:slug, :string)
    field(:deleted_at, :naive_datetime)
    field(:allow_wager, :boolean)
    field(:default_player_count, :integer)
    field(:popular_game_index, :integer)

    has_many(:team_rosters, TeamRoster)

    has_many(:game_genres, GameGenre)
    has_many(:genres, through: [:game_genres, :genre])

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :title,
      :description,
      :cover_image_url,
      :default_game_banner_url,
      :deleted_at,
      :allow_wager,
      :default_player_count,
      :logo_url,
      :short_logo,
      :popular_game_index
    ])
    |> validate_required([:title, :description, :cover_image_url, :default_game_banner_url])
    |> add_slug()
    |> unique_constraint(:slug)
    |> validate_required([:slug])
  end

  def add_slug(changeset) do
    case get_change(changeset, :title) do
      title when is_binary(title) ->
        put_change(changeset, :slug, Slug.slugify(title))

      _ ->
        changeset
    end
  end
end
