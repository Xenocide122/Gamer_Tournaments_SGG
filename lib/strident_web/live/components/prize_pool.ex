defmodule StridentWeb.Components.PrizePool do
  @moduledoc """
  Prize pool component
  """
  use StridentWeb, :live_component
  alias Strident.Prizes

  @defaults %{
    position: :horizontal,
    class: []
  }

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{prize_pool: unsorted_prize_pool} = assigns, socket)
      when is_map(unsorted_prize_pool) do
    prize_pool = sort_prize_pool_using_integer_ranks(unsorted_prize_pool)

    socket
    |> copy_parent_assigns(assigns)
    |> assign(Map.merge(@defaults, assigns))
    |> assign(:prize_pool, prize_pool)
    |> then(&{:ok, &1})
  end

  @spec sort_prize_pool_using_integer_ranks(%{String.t() => Money.t()}) :: [{integer, Money.t()}]
  defp sort_prize_pool_using_integer_ranks(unsorted_prize_pool) do
    Enum.sort_by(
      unsorted_prize_pool,
      fn
        {rank, money} when is_integer(rank) -> {rank, money}
        {rank, money} -> {String.to_integer(rank), money}
      end,
      fn {rank_0, _}, {rank_1, _} -> rank_0 < rank_1 end
    )
  end
end
