defmodule StridentWeb.TeamProfileLive.AchievementComponent do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{achievements: achievements}, socket) do
    {:ok, assign(socket, :achievements, achievements)}
  end
end
