defmodule StridentWeb.GameLive.SearchComponent do
  @moduledoc false
  use StridentWeb, :live_component

  @initial_assigns %{
    search_term: "",
    placeholder: "Search games...",
    searching: false,
    games: [],
    checked_games: []
  }

  @impl true
  def mount(socket) do
    {:ok, assign(socket, @initial_assigns)}
  end

  @impl true
  def update(%{search_result: search_result}, socket) do
    socket =
      socket
      |> assign(%{
        searching: false,
        games: search_result
      })
      |> fallback_games()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> fallback_games()

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"search_term" => search_term}, socket) do
    send(self(), {:search_games, search_term})

    socket =
      socket
      |> assign(:search_term, search_term)
      |> assign(:searching, true)

    {:noreply, socket}
  end

  defp fallback_games(%{assigns: %{search_term: ""}} = socket) do
    assign(socket, :games, socket.assigns.checked_games)
  end

  defp fallback_games(socket), do: socket
end
