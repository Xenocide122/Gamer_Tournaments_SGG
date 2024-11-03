defmodule StridentWeb.StylekitLive do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Games
  alias Strident.Tournaments
  alias Strident.Tournaments.TournamentsPageInfoCard

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(
      tournaments: Tournaments.list_tournaments_with_opts(),
      games: Games.list_games(),
      cards: TournamentsPageInfoCard.list_cards()
    )
    |> then(&{:ok, &1, layout: {StridentWeb.LayoutView, :live}})
  end

  @impl true
  @deprecated "for demo purposes only, remove before launch"
  def handle_event("randomize_progress", _value, socket) do
    {:noreply, assign(socket, stake_progress: :rand.uniform())}
  end

  @impl true
  def handle_event("toggle-modal", _payload, socket) do
    {:noreply, update(socket, :show_modal, &(!&1))}
  end

  @impl true
  def handle_event("close-modal", _payload, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end
end
