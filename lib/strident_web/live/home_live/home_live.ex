defmodule StridentWeb.HomeLive do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Games
  alias Strident.Tournaments

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Stride - The Premium Tournament Solution")
    |> assign_featured_tournaments()
    |> assign_incipient_tournaments()
    |> assign(:popular_games, Games.popular_games())
    |> then(&{:ok, &1})
  end

  defp assign_featured_tournaments(socket) do
    featured_tournaments = Tournaments.list_featured_tournaments_with_game_summaries()
    selected_featured_tournament = List.first(featured_tournaments)

    socket
    |> assign(:featured_tournaments, featured_tournaments)
    |> assign_selected_featured_tournament(selected_featured_tournament)
  end

  defp assign_incipient_tournaments(socket) do
    incipient_tournaments =
      Tournaments.list_tournaments_starting_soon(limit: 4, preloads: [:game, :participants])

    selected_incipient_tournament = List.first(incipient_tournaments)

    socket
    |> assign(:incipient_tournaments, incipient_tournaments)
    |> assign_selected_incipient_tournament(selected_incipient_tournament)
  end

  @impl true
  def handle_event("select-featured-tournament", params, socket) do
    %{featured_tournaments: featured_tournaments} = socket.assigns
    %{"featured-tournament-id" => featured_tournament_id} = params

    selected_featured_tournament =
      Enum.find(featured_tournaments, &(&1.id == featured_tournament_id))

    socket
    |> assign_selected_featured_tournament(selected_featured_tournament)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("select-incipient-tournament", params, socket) do
    %{"incipient-tournament-id" => incipient_tournament_id} = params

    socket
    |> assign(:selected_incipient_tournament_id, incipient_tournament_id)
    |> then(&{:noreply, &1})
  end

  defp assign_selected_featured_tournament(socket, selected_featured_tournament) do
    total_prize_pool =
      case selected_featured_tournament do
        nil ->
          Money.zero(:USD)

        tournament ->
          Strident.TournamentFunds.total_prize_pool(tournament, tournament.prize_strategy)
      end

    socket
    |> assign(:selected_featured_tournament, selected_featured_tournament)
    |> assign(:selected_featured_tournament_total_prize_pool, total_prize_pool)
  end

  defp assign_selected_incipient_tournament(socket, selected_incipient_tournament) do
    selected_incipient_tournament_id =
      if selected_incipient_tournament do
        selected_incipient_tournament.id
      else
        nil
      end

    socket
    |> assign(:selected_incipient_tournament_id, selected_incipient_tournament_id)
  end
end
