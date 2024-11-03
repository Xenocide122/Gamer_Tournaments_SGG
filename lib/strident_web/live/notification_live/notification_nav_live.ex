defmodule StridentWeb.NotificationLive.NotificationNavLive do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.link
        navigate="/me/notifications"
        class="flex items-center space-x-2 px-5 py-2.5 hover:bg-blackish hover:text-primary group"
      >
        <.svg icon={:bell} class="fill-white group-hover:fill-primary" width="24" height="24" />
        <p class="mr-4">Notifications</p>
        <div
          :if={@unread_notifications > 0}
          class="inline-flex items-center justify-center flex-shrink-0 w-6 h-6 rounded-full bg-secondary-dark dark:bg-secondary "
        >
          <%= @unread_notifications %>
        </div>
      </.link>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{unread_notifications: unread_notifications} = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:unread_notifications, unread_notifications)
    |> then(&{:ok, &1})
  end
end
