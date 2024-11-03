defmodule StridentWeb.TeamRostersLive.NewRoster do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{
          new_roster_name: _,
          new_roster_name_error: _,
          new_roster_game: _,
          new_roster_members: _,
          team: _,
          games: games
        } = attrs,
        socket
      ) do
    socket
    |> assign(attrs)
    |> assign(:games, sort_games_by_title(games))
    |> then(&{:ok, &1})
  end

  def sort_games_by_title(games) do
    Enum.sort_by(games, fn %{title: title} -> title end)
  end
end
