defmodule Strident.Games.MatchSetups do
  @moduledoc """
  Context for managing match setups
  """

  # TODO:
  # 1. create match setup
  # 2. update match setup. We can use `upsert` or else we need to figure when to when insert and update.
  # 3. fetch setup for given match and match_participant. Should return {:ok, match_setup} or {:error, :not_found}
end
