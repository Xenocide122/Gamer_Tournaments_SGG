defmodule StridentWeb.Components.SocialLinks do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{social_media_links: social_media_links}, socket) do
    {:ok, assign(socket, social_media_links: social_media_links)}
  end
end
