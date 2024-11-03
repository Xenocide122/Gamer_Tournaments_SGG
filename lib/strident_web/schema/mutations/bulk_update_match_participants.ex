defmodule StridentWeb.Schema.Mutations.BulkUpdateMatchParticipants do
  @moduledoc """
  A mutation to update MP scores/ranks

  Uses an input structure convenient for the mobile app
  """
  use Absinthe.Schema.Notation

  alias StridentWeb.Resolvers.MatchResolver
  alias StridentWeb.Schema.Middleware

  input_object :bulk_update_match_participants_input do
    field :participants, non_null(list_of(non_null(:update_match_participant_attrs)))
  end

  object :bulk_update_match_participants_result do
    field :errors, list_of(non_null(:input_error))
    field :match, :match
    field :match_participants, list_of(non_null(:match_participant))
  end

  object :bulk_update_match_participants_mutation do
    @desc """
    Lets tournament organizer update Match's participants' scores and ranks
    """
    field :bulk_update_match_participants, :bulk_update_match_participants_result do
      arg(:input, non_null(:bulk_update_match_participants_input))
      middleware(Middleware.Authorize, [:auth])
      resolve(&MatchResolver.bulk_update_match_participants/3)
    end
  end
end
