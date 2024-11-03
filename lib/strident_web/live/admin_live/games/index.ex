defmodule StridentWeb.GamesLive.Index do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Extension.NaiveDateTime
  alias Strident.Games
  alias StridentWeb.AdminLive.Components.Menus

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(
      games: Games.list_games(include_deleted: true),
      genres: Games.list_genres(show_hidden: true),
      filtered_games: [],
      search_term: ""
    )
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("filter-search", %{"search_term" => search_term}, socket) do
    socket
    |> assign(filtered_games: filter_games(socket.assigns.games, search_term))
    |> assign(search_term: search_term)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("disable", %{"id" => game_id}, socket) do
    Games.get_game!(game_id)
    |> update_games(NaiveDateTime.utc_now(), socket)
  end

  @impl true
  def handle_event("enable", %{"id" => game_id}, socket) do
    Games.get_game!(game_id)
    |> update_games(nil, socket)
  end

  @impl true
  def handle_event("disable-genre", %{"id" => genre_id}, socket) do
    Games.get_genre!(genre_id)
    |> update_genres(true, socket)
  end

  @impl true
  def handle_event("enable-genre", %{"id" => genre_id}, socket) do
    Games.get_genre!(genre_id)
    |> update_genres(false, socket)
  end

  @impl true
  def handle_event("disable-all-challenges", _params, socket) do
    {:noreply, socket}
  end

  defp update_games(game, deleted_at, socket) do
    case Games.update_game(game, %{deleted_at: deleted_at}) do
      {:ok, _game} ->
        games = Games.list_games(include_deleted: true)

        socket
        |> assign(games: games)
        |> assign(filtered_games: filter_games(games, socket.assigns.search_term))
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "We are unable to enable this game")
        |> then(&{:noreply, &1})
    end
  end

  defp update_genres(genre, hidden, socket) do
    case Games.update_genre(genre, %{hidden: hidden}) do
      {:ok, %{id: new_id} = new_genre} ->
        socket
        |> update(
          :genres,
          &Enum.map(&1, fn
            %{id: ^new_id} -> new_genre
            g -> g
          end)
        )
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "We are unable to enable this genre")
        |> then(&{:noreply, &1})
    end
  end

  defp filter_games(games, filter) do
    Enum.filter(games, fn g ->
      String.contains?(String.downcase(g.title), String.downcase(filter))
    end)
  end
end
