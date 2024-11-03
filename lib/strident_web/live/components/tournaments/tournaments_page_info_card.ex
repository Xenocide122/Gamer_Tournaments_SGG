defmodule StridentWeb.Components.Tournaments.TournamentsPageInfoCard do
  @moduledoc "A component card for displaying some sort of manually set info or advertisement"
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(card: assigns.card)
    |> then(&{:ok, &1})
  end
end
