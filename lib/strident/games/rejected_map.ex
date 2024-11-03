defmodule Strident.Games.RejectedMap do
  @moduledoc """
  Schema for rejected maps
  """
  use TypedEctoSchema

  import Ecto.Changeset

  @fields [
    :game_id,
    :match_participant_id,
    :rejected_map_id
  ]

  @required [
    :game_id,
    :match_participant_id,
    :rejected_map_id
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "rejected_maps" do
    belongs_to(:match, Strident.Matches.Match)
    belongs_to(:match_participant, Strident.MatchParticipants.MatchParticipant)
    belongs_to(:rejected_map, Strident.Games.GameMap)

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end
end
