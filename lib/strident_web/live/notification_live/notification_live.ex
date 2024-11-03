defmodule StridentWeb.NotificationLive.NotificationLive do
  @moduledoc false
  use StridentWeb, :live_view
  import StridentWeb.NotificationLive.Components.Card
  alias Strident.Accounts.User
  alias Strident.Notifications

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"user-notification-#{@current_user.id}"}
      class="container flex items-center px-0 py-2 mx-auto mt-32 mb-10 max-w-7xl"
    >
      <div class="ml-8">
        <h3>Notifications</h3>

        <.notification_card
          :for={notification <- @notifications}
          :if={Enum.count(@notifications) > 0}
          notification_id={notification.id}
          icon={:circle_info}
          title={notification.data["title"]}
          body={notification.data["body"]}
          action_url={notification.data["action_url"]}
          class={if(!notification.is_unread, do: "opacity-50")}
          inner_class={if(!notification.is_unread, do: "opacity-50")}
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_prams, _session, %{assigns: %{current_user: %User{}}} = socket) do
    set_timer_for_notification_to_be_read()

    socket
    |> assign_notifications()
    |> then(&{:ok, &1})
  end

  @impl true
  def mount(_prams, _params, socket) do
    socket
    |> put_flash(:error, "You need to login to access this site!")
    |> push_navigate(to: Routes.live_path(socket, StridentWeb.HomeLive))
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("click-on-notification", %{"id" => notification_id}, socket) do
    %{assigns: %{current_user: current_user}} = socket

    case Notifications.get_notifications_by(user_id: current_user.id, id: notification_id) do
      [notification] -> Notifications.notification_was_read(notification)
      _ -> :ok
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    set_timer_for_notification_to_be_read()

    socket
    |> update(:notifications, &[notification | &1])
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(:clear_unread, socket) do
    socket
    |> update(:notifications, fn notifications ->
      Enum.map(notifications, fn
        %{is_unread: true} = notification ->
          {:ok, notification} = Notifications.notification_was_read(notification)
          notification

        notification ->
          notification
      end)
    end)
    |> then(&{:noreply, &1})
  end

  defp assign_notifications(socket) do
    %{assigns: %{current_user: current_user}} = socket

    [user_id: current_user.id]
    |> Notifications.get_notifications_by()
    |> then(&assign(socket, :notifications, &1))
  end

  defp set_timer_for_notification_to_be_read do
    Process.send_after(self(), :clear_unread, 3_000)
  end
end
