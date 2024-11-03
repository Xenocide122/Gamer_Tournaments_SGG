defmodule StridentWeb.Schema.Directives.Filters do
  @moduledoc """
  Filters for various things, expressed as directives so they can
  be used dynamically in an ad-hoc way by the mobile app.
  """

  defmacro __using__(_) do
    quote do
      directive :pagination do
        @desc "Pagination"
        arg(:pagination, :pagination_args)

        on([:field, :fragment_spread, :inline_fragment])

        expand(fn args, node ->
          # e.g. relay pagination args won't be tuples, but normal args are as a Keyword
          {tuple_args, other_args} = Enum.split_with(node.arguments, &is_tuple/1)
          %{node | arguments: Keyword.merge(tuple_args, Keyword.new(args)) ++ other_args}
        end)
      end

      directive :tournament_participant_filter do
        @desc "The TournamentParticipant filter"
        arg(:filter, :tournament_participant_filter)

        on([:field, :fragment_spread, :inline_fragment])

        expand(fn args, node ->
          # e.g. relay pagination args won't be tuples, but normal args are as a Keyword
          {tuple_args, other_args} = Enum.split_with(node.arguments, &is_tuple/1)
          %{node | arguments: Keyword.merge(tuple_args, Keyword.new(args)) ++ other_args}
        end)
      end
    end
  end
end
