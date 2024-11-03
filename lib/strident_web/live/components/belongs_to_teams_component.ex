defmodule StridentWeb.Components.BelongsToTeamsComponent do
  @moduledoc """
  Belongs to
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{teams: teams}, socket) do
    {:ok, assign(socket, teams: teams)}
  end
end
