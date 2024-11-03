defmodule StridentWeb.Schema.Mutations.UpdateTournamentStatus do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias StridentWeb.Resolvers.TournamentResolver
  alias StridentWeb.Schema.Middleware

  input_object :update_tournament_status_input do
    field :id, non_null(:string)
    field :status, non_null(:tournament_status)
  end

  object :update_tournament_status_result do
    field :errors, list_of(non_null(:input_error))
    field :tournament, :tournament
  end

  object :update_tournament_status_mutation do
    @desc """
    Lets tournament organizer update the tournament status
    """
    field :update_tournament_status, :update_tournament_status_result do
      arg(:input, non_null(:update_tournament_status_input))
      middleware(Middleware.Authorize, [:auth])
      resolve(&TournamentResolver.update_tournament_status/3)
    end
  end
end
