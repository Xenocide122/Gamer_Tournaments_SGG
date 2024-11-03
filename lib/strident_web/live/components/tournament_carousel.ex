defmodule StridentWeb.Components.TournamentCarousel do
  @moduledoc false

  use StridentWeb, :live_component

  # @no_of_tournaments Enum.count(@tournaments)
  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{tournaments: tournaments} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(idx: 0)
    |> assign(%{featured_tournaments: tournaments})
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("prev", _, socket) do
    {:noreply, assign_prev_index(socket)}
  end

  @impl true
  def handle_event("next", _, socket) do
    {:noreply, assign_next_index(socket)}
  end

  def assign_prev_index(socket) do
    socket
    |> update(:idx, &(&1 - 1))
  end

  def assign_next_index(socket) do
    socket
    |> update(:idx, &(&1 + 1))
  end

  def get_tur_by_index(idx, tournaments) do
    no_of_turnaments = Enum.count(tournaments)

    case no_of_turnaments do
      0 -> []
      _ -> Enum.at(tournaments, rem(idx, no_of_turnaments))
    end
  end
end
