defmodule Strident.Games.MatchSetup do
  @moduledoc """
  Schema for match setup
  """
  use TypedEctoSchema

  import Ecto.Changeset

  @fields [
    :game_id,
    :match_participant_id,
    :selected_character_id
  ]

  @required [
    :game_id,
    :match_participant_id,
    :selected_character_id
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "match_setups" do
    belongs_to(:match, Strident.Matches.Match)
    belongs_to(:match_participant, Strident.MatchParticipants.MatchParticipant)
    belongs_to(:selected_character, Strident.Games.GameCharacter)

    has_many(:rejected_maps, Strident.Games.RejectedMap)

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end
end
