defmodule StridentWeb.Schema.DataloaderUtils do
  @moduledoc """
  Convenience functions for Dataloader config

  Read this: https://hexdocs.pm/dataloader/Dataloader.Ecto.html
  Then explain it to James.
  """
  import Ecto.Query

  alias Absinthe.Resolution
  alias Ecto.Query
  alias Ecto.Queryable
  alias Strident.EctoQueryUtils
  alias Strident.Repo
  alias Strident.Schema.ResolutionEctoUtils

  @type data_query_params :: %{
          optional(:preload) => [atom() | Keyword.t()],
          optional(:filter) => EctoQueryUtils.generic_filter(),
          optional(:sort_by) => nil | atom(),
          optional(:sort_order) => nil | :asc | :desc
        }

  @doc """
  A simple "get" of an associated schema, e.g. a tournament's game

  Use this when you don't need database-level pagination/filtering/sorting
  """
  def get_via_loader(loader, assoc_field, parent) do
    loader
    |> Dataloader.load(:data, assoc_field, parent)
    |> Dataloader.run()
    |> Dataloader.get(:data, assoc_field, parent)
  end

  @doc """
  The basic data query for resolving all "association" fields
  """
  def data, do: Dataloader.Ecto.new(Repo, query: &data_query/2)

  @doc """
  A powerful generic query, affords filtering and sorting.
  """
  @spec data_query(Queryable.t(), data_query_params()) :: Query.t()
  def data_query(queryable, params) do
    preload = Map.get(params, :preload, [])
    filter = Map.get(params, :filter, %{})
    sort_order = Map.get(params, :sort_order)
    sort_by = Map.get(params, :sort_by)

    queryable
    |> EctoQueryUtils.generic_filter(filter)
    |> then(fn queryable ->
      if is_nil(sort_by) or is_nil(sort_order) do
        queryable
      else
        order_by(queryable, {^sort_order, ^sort_by})
      end
    end)
    |> preload(^preload)
  end

  @doc """
  Analagous to Repo.one but uses Dataloader data_query

  Use this when you need database-level pagination/filtering/sorting
  """
  @spec one(Queryable.t(), data_query_params()) :: any()
  def one(queryable, params) do
    queryable
    |> data_query(params)
    |> Repo.one()
  end

  @doc """
  Analagous to Repo.paginate but uses Dataloader data_query

  Use this when you need database-level pagination/filtering/sorting
  """
  @default_pagination_limit 16
  @default_pagination_page 1
  @spec paginated_list(Queryable.t(), data_query_params()) :: Scrivener.Page.t()
  def paginated_list(queryable, params) do
    {pagination, params} = Map.pop(params, :pagination, %{})
    limit = Map.get(pagination, :limit, @default_pagination_limit)
    page = Map.get(pagination, :page, @default_pagination_page)

    queryable
    |> data_query(params)
    |> Repo.paginate(page: page, page_size: limit)
  end

  @doc """
  Analagous to get_via_loader but allows for pagination

  Use this when you need database-level pagination/filtering/sorting

  The `assoc_field_specs` is a list.
  Each element of the list can be either:
  - an atom, e.g. `:followers` or
  - a 2-tuple, e.g. `{:followers, :left}` where the 2nd element is a SQL join type
  """
  @spec paginated_assoc(Resolution.t(), [EctoQueryUtils.assoc_field_spec()]) ::
          {:ok, Scrivener.Page.t()}
  def paginated_assoc(resolution, assoc_field_specs) do
    parent_queryable = Map.get(resolution.source, :__struct__)
    id = resolution.source.id
    params = params_from_resolution(resolution)
    {pagination, _params} = Map.pop(params, :pagination, %{})
    limit = Map.get(pagination, :limit, @default_pagination_limit)
    page = Map.get(pagination, :page, @default_pagination_page)

    filter = Map.get(params, :filter, %{})
    sort_order = Map.get(params, :sort_order)
    sort_by = Map.get(params, :sort_by) |> ResolutionEctoUtils.sort_by_atom()

    parent_queryable
    |> where([q], q.id == ^id)
    |> EctoQueryUtils.recursive_join(assoc_field_specs)
    |> EctoQueryUtils.generic_filter(filter, false)
    |> then(fn query ->
      if is_nil(sort_by) or is_nil(sort_order) do
        query
      else
        order_by(query, [..., q], {^sort_order, field(q, ^sort_by)})
      end
    end)
    |> select([..., q], q)
    |> Repo.paginate(page: page, page_size: limit)
    |> then(&{:ok, &1})
  end

  @spec params_from_resolution(Resolution.t()) :: map()
  defp params_from_resolution(resolution) do
    Map.new(resolution.definition.arguments)
  end
end
