defmodule StridentWeb.Schema.Queries.Game do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias StridentWeb.Resolvers.GameResolver

  object :game_queries do
    @desc "List all games"
    field :games, list_of(:game) do
      resolve(&GameResolver.list_games/3)
    end
  end
end
