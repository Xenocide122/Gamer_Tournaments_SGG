defmodule Strident.Schema.ResolutionEctoUtils do
  @moduledoc """
  Functions to streamline some of our Resolution-Ecto conventions
  """

  alias Absinthe.Resolution

  @type pagination :: %{
          optional(:limit) => non_neg_integer(),
          optional(:page) => non_neg_integer()
        }
  @type arg :: {:pagination, pagination} | {:sort_order, :asc | :desc} | {:sort_by, atom()}
  @type args :: [arg()]

  @spec query_arguments(Resolution.t()) :: args()
  def query_arguments(resolution) do
    opts = resolution.definition.arguments || []

    opts
    |> ensure_sort_by_is_known_atom()
  end

  @spec ensure_sort_by_is_known_atom(args()) :: args()
  def ensure_sort_by_is_known_atom(opts) do
    case Keyword.get(opts, :sort_by) do
      sort_by when is_binary(sort_by) ->
        Keyword.put(opts, :sort_by, sort_by_atom(sort_by))

      _ ->
        opts
    end
  end

  @spec sort_by_atom(binary() | nil) :: atom()
  def sort_by_atom(nil), do: nil

  def sort_by_atom(sort_by) do
    sort_by
    |> Macro.underscore()
    |> String.to_existing_atom()
  end
end
