defmodule StridentWeb.Schema.Queries.Tournament do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias StridentWeb.Resolvers.TournamentResolver
  alias StridentWeb.Schema.ComplexityAnalysis
  alias StridentWeb.Schema.Middleware

  object :tournament_queries do
    @desc "Get list of tournaments"
    field :list_tournaments, :list_of_tournaments do
      arg(:pagination, :pagination_args)
      arg(:search_term, :string)
      arg(:times, list_of(:naive_datetime))
      arg(:dates, list_of(:date))
      arg(:games, list_of(:string))
      arg(:status, list_of(:tournament_status))
      arg(:exclude_statuses, list_of(:tournament_status))
      arg(:with_creator_or_participant, :string)
      resolve(&TournamentResolver.list_tournaments/3)
      complexity(&ComplexityAnalysis.complexity_for_list/3)
    end

    @desc "Get list of featured tournaments"
    field :list_featured_tournaments, list_of(non_null(:tournament)) do
      resolve(&TournamentResolver.list_featured_tournaments/3)
    end

    @desc "List tournament which I'm owner or participating in or invited to."
    field :list_my_tournaments, :list_of_tournaments do
      arg(:pagination, :pagination_args)
      arg(:search_term, :string)
      arg(:times, list_of(:naive_datetime))
      arg(:dates, list_of(:date))
      arg(:games, list_of(:string))
      arg(:status, list_of(:tournament_status))
      middleware(Middleware.Authorize, [:auth])
      resolve(&TournamentResolver.list_my_tournaments/3)
    end

    @desc "Get tournament by ID."
    field :get_tournament, :tournament do
      arg(:id, non_null(:string))
      resolve(&TournamentResolver.get_tournament/3)
    end

    @desc "List Participants for tournament."
    field :list_tournament_participants, :list_of_tournament_participants do
      arg(:pagination, :pagination_args)
      arg(:filter, :tournament_participant_filter)
      arg(:search_term, :string)
      resolve(&TournamentResolver.list_tournament_participants/3)
      complexity(&ComplexityAnalysis.complexity_for_list/3)
    end
  end
end
