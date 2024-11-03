defmodule StridentWeb.GamesLive.Edit do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Games

  def mount(%{"id" => id}, _session, socket) do
    game = Games.get_game_with_preloads_by([id: id], [:genres])

    socket
    |> assign(game: game)
    |> then(&{:ok, &1})
  end
end
