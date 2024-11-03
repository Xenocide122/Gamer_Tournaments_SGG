defmodule StridentWeb.Components.Follow do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{following_user: following_user}, socket) do
    {:ok, assign(socket, following_user: following_user)}
  end
end
