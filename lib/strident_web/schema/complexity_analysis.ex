defmodule StridentWeb.Schema.ComplexityAnalysis do
  @moduledoc """
  Convenience functions for analyzing query complexity
  """

  @type arguments :: %{atom => any}
  @type complexity :: non_neg_integer()

  @spec complexity_for_list(arguments, complexity, Absinthe.Complexity.t()) :: complexity
  def complexity_for_list(arguments, child_complexity, _metadata) do
    page_size = page_size_or_limit(arguments)
    child_complexity * page_size
  end

  @spec page_size_or_limit(arguments) :: complexity()
  defp page_size_or_limit(%{pagination: %{limit: limit}}), do: limit
  defp page_size_or_limit(%{}), do: 0
end
