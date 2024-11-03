defmodule StridentWeb.Components.Tournaments.SmallCarouselTournamentCard do
  @moduledoc "A smaller featured tournament background"
  use StridentWeb, :live_component

  alias Strident.Tournaments

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(tournament: assigns.tournament)
    |> assign_tournament_link_to()
    |> then(&{:ok, &1})
  end

  defp assign_tournament_link_to(socket) do
    url =
      if Tournaments.can_manage_tournament?(
           Map.get(socket.assigns, :current_user),
           socket.assigns.tournament
         ) do
        Routes.live_path(
          StridentWeb.Endpoint,
          StridentWeb.TournamentDashboardLive,
          socket.assigns.tournament.slug
        )
      else
        Routes.tournament_show_pretty_path(
          StridentWeb.Endpoint,
          :show,
          socket.assigns.tournament.slug
        )
      end

    assign(socket, tournament_link_to: url)
  end
end
