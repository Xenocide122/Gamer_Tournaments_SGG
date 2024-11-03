defmodule StridentWeb.Schema.Types.MatchReport do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :match_report do
    field(:id, non_null(:string))
    field(:match, non_null(:match), resolve: dataloader(:data))
    field(:match_participant, non_null(:match_participant), resolve: dataloader(:data))

    @desc """
    A map of MatchParticipant IDs to scores
    """
    field(:reported_score, :json)
  end
end
