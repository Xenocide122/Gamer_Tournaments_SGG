defmodule StridentWeb.Components.Tournaments.SmallCarouselTournamentScroll do
  @moduledoc "A smaller featured tournaments carousel"
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(tournaments: assigns.tournaments)
    |> then(&{:ok, &1})
  end
end
