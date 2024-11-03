defmodule StridentWeb.Schema.Mutations.MatchReport do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias StridentWeb.Resolvers.MatchReportResolver
  alias StridentWeb.Schema.Middleware

  input_object :create_match_report_input do
    field(:match_id, non_null(:string))
    field(:reported_score, non_null(:json))
  end

  object :create_match_report_result do
    field(:errors, list_of(non_null(:input_error)))
    field(:match_report, :match_report)
  end

  object :match_report_mutations do
    @desc """
    Creates a MatchReport.

    if is final report on match, and if all match reports accord,
    then this may cause a winner to be marked on the match.
    """
    field :create_match_report, :create_match_report_result do
      arg(:input, non_null(:create_match_report_input))
      middleware(Middleware.Authorize, [:auth])
      resolve(&MatchReportResolver.create_match_report/3)
    end
  end
end
