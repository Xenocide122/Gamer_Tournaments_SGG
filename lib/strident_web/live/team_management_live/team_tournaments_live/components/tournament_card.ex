defmodule StridentWeb.TeamTournamentsLive.Components.TournamentCard do
  @moduledoc """
  Tournament card
  """
  use StridentWeb, :live_component
  alias Strident.Extension.NaiveDateTime

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{open_modal: true}, socket) do
    {:ok, assign(socket, :open_manage_tournament_participant, true)}
  end

  @impl true
  def update(%{open_modal: false}, socket) do
    {:ok, assign(socket, :open_manage_tournament_participant, false)}
  end

  @impl true
  def update(%{tournament: tournament, team: team}, socket) do
    socket
    |> assign(:tournament, tournament)
    |> assign(:team, team)
    |> assign(:link_to, Routes.tournament_show_pretty_path(socket, :show, tournament.slug, []))
    |> assign(
      :image_url,
      tournament.thumbnail_image_url ||
        safe_static_url("/images/tournament-image-placeholder.jpg")
    )
    |> assign(:open_manage_tournament_participant, false)
    |> then(&{:ok, &1})
  end

  defp is_future?(datetime) do
    NaiveDateTime.compare(datetime, NaiveDateTime.utc_now()) == :gt
  end
end
