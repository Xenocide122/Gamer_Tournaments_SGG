defmodule StridentWeb.Components.FavoriteGamesComponent do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, edit_games: false)}
  end

  @impl true
  def update(%{user: _, current_user: _, games: _} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("toggle-edit-games", _params, %{assigns: %{edit_games: edit_games}} = socket) do
    {:noreply, assign(socket, edit_games: not edit_games)}
  end

  defp is_game_selected(game, favorite_games) do
    Enum.any?(favorite_games, &(&1.id == game.id))
  end
end
