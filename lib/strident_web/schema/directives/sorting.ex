defmodule StridentWeb.Schema.Directives.Sorting do
  @moduledoc """
  Generic sorting for everything
  """

  defmacro __using__(_) do
    quote do
      directive :sorting do
        @desc "The sorting order, either ASC or DESC"
        arg(:sort_order, type: :sort_order, default_value: :desc)
        @desc "The name of the field to sort by"
        arg(:sort_by, type: :string, default_value: "inserted_at")

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
