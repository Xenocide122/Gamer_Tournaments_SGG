defmodule StridentWeb.InitAssigns do
  @moduledoc false
  import Phoenix.LiveView
  import Phoenix.Component
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias StridentWeb.HomeLive
  alias StridentWeb.LiveViewHelpers
  alias StridentWeb.Router.Helpers, as: Routes
  alias StridentWeb.UserLogInLive

  @dialyzer {:no_match, send_metrics: 2}

  @default_locale Application.compile_env(:strident, :default_locale)
  @default_timezone Application.compile_env(:strident, :default_timezone)

  # Ensures common `assigns` are applied to all LiveViews
  # that attach this module as an `on_mount` hook
  def on_mount(:default, params, session, socket) do
    socket
    |> assign_stuff(params, session)
    |> send_page_to_mixpanel(params, session)
    |> then(&{:cont, &1})
  end

  def on_mount(live_session_name, params, session, socket)
      when live_session_name in [:authenticated_user, :authenticated_confirmed_user] do
    socket
    |> assign_stuff(params, session)
    |> cont_or_halt_if_no_current_user()
  end

  def on_mount(:unauthenticated_user, params, session, socket) do
    case assign_stuff(socket, params, session) do
      %{assigns: %{current_user: %{id: _}}} = socket ->
        socket
        |> redirect(
          to: socket.assigns.path || Routes.live_path(socket, Routes.live_path(socket, HomeLive))
        )
        |> then(&{:halt, &1})

      socket ->
        {:cont, socket}
    end
  end

  def on_mount(:staff_user, params, session, socket) do
    case assign_stuff(socket, params, session) do
      %{assigns: %{current_user: %{is_staff: true}}} = socket ->
        {:cont, socket}

      socket ->
        socket
        |> redirect(to: Routes.live_path(socket, Routes.live_path(socket, HomeLive)))
        |> then(&{:halt, &1})
    end
  end

  defp cont_or_halt_if_no_current_user(socket) do
    case socket do
      %{assigns: %{current_user: %{id: _}}} = socket ->
        {:cont, socket}

      socket ->
        socket
        |> put_flash(:error, "Please log in to access this page.")
        |> redirect(to: Routes.live_path(socket, UserLogInLive))
        |> then(&{:halt, &1})
    end
  end

  defp assign_stuff(socket, params, session) do
    user =
      case {socket, session} do
        {%{assigns: %{current_user: current_user}}, _session} ->
          current_user

        {_socket, %{"current_user_id" => nil}} ->
          nil

        {_socket, %{"current_user_id" => current_user_id}} ->
          Accounts.get_user_with_credentials!(current_user_id)

        {_socket, %{"user_token" => user_token}} ->
          get_user(user_token)

        {_socket, _session} ->
          nil
      end

    user = user && Accounts.preload_credentials(user)

    socket
    |> manage_locale_timezone(session, user)
    |> assign(user_return_to: session["user_return_to"] || "/")
    |> assign_new(:is_using_vpn, fn -> session["is_using_vpn"] end)
    |> assign_new(:show_vpn_banner, fn -> session["show_vpn_banner"] end)
    |> assign_new(:check_timezone, fn -> session["check_timezone"] end)
    |> assign_new(:current_user, fn -> user end)
    |> LiveViewHelpers.assign_debug_mode(params, session)
    |> assign_new(:current_ip, fn -> session["remote_ip"] end)
    |> assign_new(:is_bot, fn -> session["is_bot"] end)
    |> assign_new(:ip_location, fn -> session["ip_location"] end)
    |> assign_new(:impersonating_staff_id, fn -> session["impersonating_staff_id"] end)
    |> assign_new(:can_stake, fn -> set_geographic_restriction(:can_stake, session) end)
    |> assign_new(:can_play, fn -> set_geographic_restriction(:can_play, session) end)
    |> assign_new(:can_wager, fn -> set_geographic_restriction(:can_wager, session) end)
  end

  defp set_geographic_restriction(feature, session), do: session[Atom.to_string(feature)]

  defp manage_locale_timezone(socket, session, %{locale: locale} = user) do
    socket
    |> assign(:locale, locale)
    |> update_timezone(session, user)
  end

  defp manage_locale_timezone(socket, session, _user) do
    socket
    |> assign_new(:timezone, fn -> get_timezone(session) end)
    |> assign_new(:locale, fn -> get_locale(session) end)
  end

  defp update_timezone(socket, session, user) do
    timezone =
      if user.use_location_timezone,
        do: session["timezone"],
        else: user.timezone

    assign(socket, timezone: timezone)
  end

  defp get_timezone(%{"ip_location" => %{timezone: timezone}}), do: timezone
  defp get_timezone(_session), do: @default_timezone

  defp get_locale(%{"ip_location" => %{locale: locale}}), do: locale
  defp get_locale(_user), do: @default_locale

  defp get_user(user_token) when is_binary(user_token) do
    Accounts.get_user_by_session_token(user_token)
  end

  defp get_user(_), do: nil

  defp send_page_to_mixpanel(socket, params, _session) do
    tap(socket, fn socket ->
      if connected?(socket) do
        send_metrics(socket, params)
      end
    end)
  end

  @spec send_metrics(Phoenix.LiveView.Socket.t(), map() | atom()) :: :ok
  defp send_metrics(%{assigns: %{current_user: %User{} = user}} = socket, params) do
    Segment.Analytics.track(
      user.id,
      "Visit Site",
      if(is_map(params), do: params, else: %{})
      |> Map.put("page", socket.view)
      |> Map.put("is_staff", user.is_staff)
    )
  end

  defp send_metrics(socket, params) do
    Segment.Analytics.track(
      "__anonymous__",
      "Visit Site",
      if(is_map(params), do: params, else: %{})
      |> Map.put("page", socket.view)
      |> Map.put("is_staff", false)
    )
  end
end
