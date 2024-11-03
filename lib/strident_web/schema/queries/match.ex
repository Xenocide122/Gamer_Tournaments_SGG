defmodule StridentWeb.Schema.Queries.Match do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias StridentWeb.Resolvers.MatchResolver

  object :match_queries do
    @desc "Get a match by ID"
    field :get_match, :match do
      arg(:id, non_null(:string))
      resolve(&MatchResolver.get_match/3)
    end
  end
end
