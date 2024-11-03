defmodule Strident.Games.GameMap do
  @moduledoc """
  Schema for game map, a match participant can choose not to play at.
  """
  use TypedEctoSchema

  import Ecto.Changeset

  @fields [
    :game_id,
    :map_label,
    :is_striked
  ]

  @required [
    :game_id,
    :map_label,
    :is_striked
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "game_maps" do
    field(:name, :string)

    belongs_to(:game, Strident.Games.Game)

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end
end
