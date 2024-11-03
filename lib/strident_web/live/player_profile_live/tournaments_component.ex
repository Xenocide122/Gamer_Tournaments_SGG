defmodule StridentWeb.PlayerProfileLive.TournamentsComponent do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Extension.NaiveDateTime

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :selected_filter, "all")}
  end

  @impl true
  def update(%{tournaments: tournaments} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:tournaments, tournaments)
    |> assign(:show_tournaments, tournaments)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("filter-all", _params, %{assigns: %{tournaments: tournaments}} = socket) do
    socket =
      socket
      |> assign(:show_tournaments, tournaments)
      |> assign(:selected_filter, "all")

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter-upcoming", _params, %{assigns: %{tournaments: tournaments}} = socket) do
    filtered_tournaments =
      Enum.filter(tournaments, fn
        %{starts_at: datetime} ->
          NaiveDateTime.compare(NaiveDateTime.utc_now(), datetime) == :lt
      end)

    socket =
      socket
      |> assign(:show_tournaments, filtered_tournaments)
      |> assign(:selected_filter, "upcoming")

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter-past", _params, %{assigns: %{tournaments: tournaments}} = socket) do
    filtered_tournaments = Enum.filter(tournaments, &Map.get(&1, :concluded))

    socket =
      socket
      |> assign(:show_tournaments, filtered_tournaments)
      |> assign(:selected_filter, "past")

    {:noreply, socket}
  end

  @impl true
  def handle_event("go-to-tournament", %{"tournament" => tournament}, socket) do
    route = Routes.tournament_show_path(StridentWeb.Endpoint, :show, tournament)
    {:noreply, push_navigate(socket, to: route)}
  end
end
