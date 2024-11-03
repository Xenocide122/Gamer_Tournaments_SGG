defmodule StridentWeb.Components.PrizeDistribution do
  @moduledoc """
  Prize Distribution component
  """
  use StridentWeb, :live_component
  alias Strident.Prizes

  @impl true
  def mount(socket) do
    socket
    |> assign(:position, :horizontal)
    |> assign(:class, [])
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{prize_distribution: unsorted_prize_distribution} = assigns, socket)
      when is_map(unsorted_prize_distribution) do
    prize_distribution = sort_prize_distribution_using_integer_ranks(unsorted_prize_distribution)

    socket
    |> copy_parent_assigns(assigns)
    |> assign(assigns)
    |> assign(:prize_distribution, prize_distribution)
    |> then(&{:ok, &1})
  end

  @spec sort_prize_distribution_using_integer_ranks(%{String.t() => Decimal.t()}) :: [
          {integer, Decimal.t()}
        ]
  defp sort_prize_distribution_using_integer_ranks(unsorted_prize_distribution) do
    Enum.sort_by(
      unsorted_prize_distribution,
      fn
        {rank, percentage} when is_integer(rank) -> {rank, percentage}
        {rank, percentage} -> {String.to_integer(rank), percentage}
      end,
      fn {rank_0, _}, {rank_1, _} -> rank_0 < rank_1 end
    )
  end
end
