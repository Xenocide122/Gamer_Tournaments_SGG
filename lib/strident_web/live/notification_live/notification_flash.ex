defmodule StridentWeb.NotificationLive.NotificationFlash do
  @moduledoc false
  use StridentWeb, :live_view
  import StridentWeb.NotificationLive.Components.Card
  alias Strident.Accounts.User
  alias Strident.Notifications
  alias Strident.NotifyClient

  @impl true
  def render(assigns) do
    ~H"""
    <.notification_badge
      :for={notification <- @new_notifications}
      :if={Enum.count(@new_notifications) > 0}
      notification_id={notification.id}
      icon={:circle_info}
      title={notification.data.title}
      body={notification.data.body}
      action_url={notification.data.action_url}
      class="absolute hidden w-1/4 -top-36 right-10 md:block"
    />
    """
  end

  @impl true
  def mount(:not_mounted_at_router, session, socket) do
    %{"current_user_id" => current_user_id} = session
    do_mount(socket, current_user_id)
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %User{}}} = socket) do
    %{assigns: %{current_user: current_user}} = socket
    do_mount(socket, current_user.id)
  end

  defp do_mount(socket, current_user_id) do
    if connected?(socket) and !!current_user_id,
      do: NotifyClient.subscribe_to_events_affecting_user(current_user_id)

    socket
    |> assign(:current_user_id, current_user_id)
    |> assign(:new_notifications, [])
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("click-on-notification", %{"id" => notification_id}, socket) do
    %{assigns: %{current_user_id: current_user_id}} = socket

    case Notifications.get_notifications_by(user_id: current_user_id, id: notification_id) do
      [notification] -> Notifications.notification_was_read(notification)
      _ -> :ok
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    Process.send_after(self(), :clear_new_notification, 15_000)

    socket
    |> update(:new_notifications, &[notification | &1])
    |> then(&{:noreply, &1})
  end

  def handle_info(:clear_new_notification, socket) do
    socket
    |> update(:new_notifications, &(&1 |> Enum.reverse() |> tl() |> Enum.reverse()))
    |> then(&{:noreply, &1})
  end
end
