defmodule StridentWeb.Schema.Types.Stage do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc """
  A Stage is a typical tournament stage.
  """
  object :stage do
    field(:id, non_null(:string))

    @desc """
    - single_elimination
    - double_elimination
    - round_robin
    - swiss
    """
    field(:type, non_null(:stage_type))

    @desc """
    - `scheduled`: means stage has not started yet
    - `in_progress`: means stage is currently ongoing(previous stages should be `finished` and later stages should be `scheduled`.)
    - `requires_tiebreaking`: means someone (usually the TO) has to manually break StageParticipant ties.
    - `finished`: means stage has played all matches and all scores/winners have been marked.
    """
    field(:status, non_null(:stage_status))

    field(:round, :integer)

    field :matches, list_of(:match) do
      arg(:filter, :match_filter)
      resolve(dataloader(:data))
    end
  end

  enum :stage_status do
    value(:scheduled, description: "stage has not started yet")

    value(:in_progress,
      description:
        "stage is currently ongoing(previous stages should be `finished` and later stages should be `scheduled`.)"
    )

    value(:requires_tiebreaking,
      description: "someone (usually the TO) has to manually break StageParticipant ties."
    )

    value(:finished,
      description: "stage has played all matches and all scores/winners have been marked."
    )
  end

  enum :stage_type do
    value(:single_elimination)
    value(:double_elimination)
    value(:round_robin)
    value(:swiss)
    value(:battle_royale)
  end

  @desc "Filtering options for Stages"
  input_object :stage_filter do
    @desc "Matching the stage id"
    field(:id, :string)
  end
end
