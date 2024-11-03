defmodule Strident.Games.GameCharacter do
  @moduledoc false

  use TypedEctoSchema

  import Ecto.Changeset

  alias Strident.Games.Game

  @primary_key {:id, :binary_id, autogenerate: true}
  typed_schema "game_characters" do
    field :icon_url, :string
    field :name, :string

    belongs_to :game, Game, type: :binary_id
    timestamps()
  end

  def changeset(game_character, attrs) do
    game_character
    |> cast(attrs, [:icon_url, :name, :game_id])
    |> validate_required([:name, :game_id])
    |> assoc_constraint(:game)
  end
end
