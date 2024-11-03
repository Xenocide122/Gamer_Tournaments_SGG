defmodule StridentWeb.HomepageLive.Index do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Games
  alias StridentWeb.AdminLive.Components.Menus

  @impl true
  def mount(_params, _session, socket) do
    popular_games =
      Games.popular_games()
      |> Enum.map(& &1.id)

    all_games = Games.list_games(include_deleted: false)

    socket
    |> assign(
      games: all_games,
      select_options: Enum.map(all_games, &{&1.title, &1.id}),
      homepage_popular_games: popular_games,
      form_games: popular_games
    )
    |> assign(:form, to_form(%{}, as: :homepage_popular_games))
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("update-popular-games", %{"homepage_popular_games" => params}, socket) do
    socket
    |> update_games_list(params)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("create-hpg", _params, socket) do
    socket
    |> update(
      :form_games,
      &List.insert_at(&1, -1, nil)
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("delete-hpg", %{"index" => i}, socket) do
    i = String.to_integer(i)
    new_games = List.delete_at(socket.assigns.form_games, i)

    socket
    |> update_games_list(new_games)
    |> assign(:form_games, new_games)
    |> then(&{:noreply, &1})
  end

  defp update_games_list(socket, params) do
    case Games.update_popular_games(
           Enum.uniq(params),
           socket.assigns.homepage_popular_games,
           socket.assigns.games
         ) do
      {:ok, %{update: popular_games}} ->
        popular_games = Enum.map(popular_games, & &1.id)

        socket
        |> assign(
          homepage_popular_games: popular_games,
          form_games: popular_games
        )

      _error ->
        put_flash(socket, :error, "Could not update popular games")
    end
  end
end
