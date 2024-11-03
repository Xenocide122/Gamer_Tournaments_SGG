defmodule StridentWeb.Components.Tournaments.HoverTournamentCard do
  @moduledoc """
  New Tournament card
  Params
  `tournament`
  `allow_hover_default`: optional, set to `false` to prevent hover animation without attribute being set by parent container. default `true`
  """
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
    |> assign(:tournament, assigns.tournament)
    |> assign(:allow_hover_default, Map.get(assigns, :allow_hover_default, true))
    |> assign_tournament_link_to()
    |> assign_number_of_confirmed_participants()
    |> assign_team_size_label()
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

  defp assign_number_of_confirmed_participants(socket) do
    %{tournament: tournament} = socket.assigns

    tournament.participants
    |> Enum.count(&(&1.status in Tournaments.on_track_statuses()))
    |> then(&assign(socket, :number_of_confirmed_participants, &1))
  end

  defp assign_team_size_label(socket) do
    %{tournament: tournament} = socket.assigns

    team_size_label =
      case tournament.players_per_participant do
        1 -> "1 v 1"
        2 -> "Duos"
        3 -> "Trios"
        n -> "#{n} v #{n}"
      end

    assign(socket, :team_size_label, team_size_label)
  end
end
