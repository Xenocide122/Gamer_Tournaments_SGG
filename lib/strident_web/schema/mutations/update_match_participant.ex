defmodule StridentWeb.Schema.Mutations.UpdateMatchParticipant do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias StridentWeb.Resolvers.MatchParticipantResolver
  alias StridentWeb.Schema.Middleware

  input_object :update_match_participant_input do
    field :id, non_null(:id)
    field :attrs, non_null(:update_match_participant_attrs)
  end

  input_object :update_match_participant_attrs do
    field(:id, :string)
    field(:score, :string)
    field(:rank, :integer)
  end

  object :update_match_participant_result do
    field :errors, list_of(non_null(:input_error))
    field :match_participant, :match_participant
  end

  object :update_match_participant_mutation do
    @desc """
    Lets tournament organizer update the MatchParticipant
    """
    field :update_match_participant, :update_match_participant_result do
      arg(:input, non_null(:update_match_participant_input))
      middleware(Middleware.Authorize, [:auth])
      resolve(&MatchParticipantResolver.update_match_participant/3)
    end
  end
end
