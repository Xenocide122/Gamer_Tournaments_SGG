defmodule StridentWeb.UserSettingsLive do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns do
      %{current_user: %User{}} ->
        socket
        |> assign(page_title: "Account Settings")
        |> then(&{:ok, &1})

      _ ->
        socket
        |> push_redirect(to: "/")
        |> then(&{:ok, &1})
    end
  end

  @impl true
  def handle_info({:current_user_updated, attrs}, socket) do
    socket
    |> update(
      :current_user,
      &Enum.reduce(attrs, &1, fn {key, value}, user ->
        Map.put(user, key, value)
      end)
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:locale_updated, %{locale: locale}}, socket) do
    socket
    |> assign(:locale, locale)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:timezone_updated, %{timezone: timezone}}, socket) do
    socket
    |> assign(:timezone, timezone)
    |> then(&{:noreply, &1})
  end
end
