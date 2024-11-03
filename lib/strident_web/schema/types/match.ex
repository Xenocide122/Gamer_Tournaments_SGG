defmodule StridentWeb.Schema.Types.Match do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  require Logger
  alias StridentWeb.Schema.DataloaderUtils

  object :list_of_matches do
    field(:entries, list_of(non_null(:match)))
    field(:page_number, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:total_entries, :integer)
  end

  @desc """
  A Match is a typical tournament match.

  It at least 0 participants.
  It usually has 0, 1 or 2 participants.

  A match's "child edge" is any edge where the match is a parent.
  A match's "parent edge" is any edge where the match is a child.

  A match is one of 5 possible types:
  - `standard` - the default type, used for single_elimination Stages
  - `upper` - for a double_elimination Stage only
  - `lower` - for a double_elimination Stage only
  - `pool` - for round-robin pool stages, where we should never have MatchEdges.
  - `swiss` - for Swiss pool stages, where we should never have MatchEdges.
  - `battle_royale` - for Swiss pool stages, where we should never have MatchEdges.
  """
  object :match do
    field(:id, non_null(:string))
    field(:type, non_null(:string))
    field(:stage, non_null(:stage), resolve: dataloader(:data))
    field(:participants, list_of(:match_participant), resolve: dataloader(:data))

    @desc """
    The "children matches" of a match `P` are all the matches whose
    participants are directly determined by the ranks of `P`'s participants..

    In a "pool" type stage, e.g. Swiss or Round-Robin, the matches have no children,
    since it is provable that
    1. in Swiss every match is a parent of every match in the next round
    2. in Round-Robin, the participants of a match are pre-determined before any match is played.
    """
    field(:children, list_of(non_null(:match)), resolve: dataloader(:data))

    @desc """
    See description for `children`
    """
    field(:parents, list_of(non_null(:match)), resolve: dataloader(:data))

    @desc """
    The "round" this match is in

    match.round == 0  <=> "first round match"

    You can expect this to be true, unless the match has no parents or children:

    ```javascript
    match.round == match.parents[0].round + 1
    match.round == match.children[0].round - 1
    ```
    """
    field(:round, non_null(:integer))

    @desc """
    myMatchReport is just a normal matchReport

    It will be NULL unless current user is a player for the
    tournamentParticipant associated with the
    matchParticipant who created the matchReportthis

    It may also be NULL if simply hasn't been reported yet.

    To ask the question "do I need to report a score", query for:

    ```
    tournament {
      myParticipant {
        nextMatch {
          myMatchReport {
            reportedScore
          }
        }
      }
    }
    ```

    if `myParticipant` and `nextMatch` are not null AND
    `myMatchReport` is NULL
    then the user should report the score.
    """
    field :my_match_report, :match_report do
      resolve(fn match, _args, resolution ->
        with %{current_user: %{id: user_id}, loader: loader} <- resolution.context,
             [match_report] <-
               DataloaderUtils.get_via_loader(
                 loader,
                 {:match_reports,
                  [
                    filter: %{
                      match_participant: %{
                        tournament_participant: %{players: %{user: %{id: user_id}}}
                      }
                    }
                  ]},
                 match
               ) do
          {:ok, match_report}
        else
          _ -> {:ok, nil}
        end
      end)
    end
  end

  @desc "Filtering options for Matches"
  input_object :match_filter do
    @desc "Matching the match round"
    field(:round, :integer)
    @desc "Matching the match type"
    field(:type, :string)
  end
end
