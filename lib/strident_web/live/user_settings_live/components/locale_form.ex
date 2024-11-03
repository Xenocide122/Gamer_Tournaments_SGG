defmodule StridentWeb.UserSettingsLive.LocaleForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.CldrUtils

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    locales = CldrUtils.known_locales_as_humanized_strings()

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:changeset, Accounts.change_user_locale(assigns.current_user))
    |> assign(:locales, locales)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_user_locale(socket.assigns.current_user, params) do
      {:ok, user} ->
        socket =
          socket
          |> assign(current_user: user)
          |> put_flash(:info, "Location updated successfully!")

        send(self(), {:current_user_updated, %{locale: user.locale}})
        send(self(), {:locale_updated, %{locale: user.locale}})
        {:noreply, socket}

      {:error, _changeset} ->
        socket
        |> put_flash(:error, "Could not update settings.")
        |> then(&{:noreply, &1})
    end
  end
end
