defmodule StridentWeb.Schema.Types.MatchParticipant do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc """
  A MatchParticipant is an entity that participates in a tournament match.
  It is associated with either a Team or a Party.
  """
  object :match_participant do
    field(:id, non_null(:string))
    field(:match, non_null(:match), resolve: dataloader(:data))
    field(:tournament_participant, non_null(:tournament_participant), resolve: dataloader(:data))

    @desc """
    Rank. A non-negative integer. rank 0 == 1st place
    """
    field(:rank, :integer)

    @desc """
    Their score. A string.
    """
    field(:score, :string)
  end
end
