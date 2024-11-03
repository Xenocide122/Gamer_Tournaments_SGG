defmodule StridentWeb.Live.UserSettingsLive.Components.TimezoneForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    timezones =
      Cldr.Timezone.timezones() |> Enum.flat_map(fn {_key, values} -> values end) |> Enum.sort()

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:changeset, Accounts.change_user_timezone(assigns.current_user))
    |> assign(:timezones, timezones)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_user_timezone(socket.assigns.current_user, params) do
      {:ok, user} ->
        socket =
          socket
          |> assign(current_user: user)
          |> put_flash(:info, "Timezone updated successfully!")

        send(self(), {:current_user_updated, %{locale: user.locale}})
        send(self(), {:timezone_updated, %{timezone: user.timezone}})
        {:noreply, socket}

      {:error, _changeset} ->
        socket
        |> put_flash(:error, "Could not update timezone.")
        |> then(&{:noreply, &1})
    end
  end
end
