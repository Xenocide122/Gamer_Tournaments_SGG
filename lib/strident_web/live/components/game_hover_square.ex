defmodule StridentWeb.Components.GameHoverSquare do
  @moduledoc """
  Hover square for games
  """
  use StridentWeb, :live_component
  alias Strident.Games

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(game: assigns.game)
    |> then(&{:ok, &1})
  end
end
