defmodule StridentWeb.NavbarLive do
  @moduledoc """
  Navbar component
  """
  use StridentWeb, :live_view

  import StridentWeb.NavbarLive.Compoenets.Widgets

  alias Strident.Accounts
  alias Strident.Notifications
  alias Strident.NotifyClient
  alias Strident.SocialMedia
  alias StridentWeb.SearchLive
  alias StridentWeb.SegmentAnalyticsHelpers
  alias Phoenix.LiveView.JS

  @show_create_tournament_link Application.compile_env(:strident, :env) in [:dev, :test] or
                                 !is_nil(System.get_env("IS_STAGING"))

  @impl true
  def mount(:not_mounted_at_router, session, socket) do
    ip_location =
      if session["ip_location"],
        do: session["ip_location"],
        else: %{
          region_name: "Unable to locate",
          country_name: ""
        }

    impersonating_staff_id =
      if session["impersonating_staff_id"],
        do: session["impersonating_staff_id"],
        else: nil

    %{
      "timezone" => timezone,
      "locale" => locale,
      "can_stake" => can_stake,
      "can_play" => can_play,
      "can_wager" => can_wager,
      "is_using_vpn" => is_using_vpn,
      "show_vpn_banner" => show_vpn_banner,
      "check_timezone" => check_timezone
    } = session

    socket
    |> assign_current_user_from_session_token(session)
    |> assign(:timezone, timezone)
    |> assign(:impersonating_staff_id, impersonating_staff_id)
    |> assign(:locale, locale)
    |> assign(:can_stake, can_stake)
    |> assign(:can_play, can_play)
    |> assign(:can_wager, can_wager)
    |> assign(:is_using_vpn, is_using_vpn)
    |> assign(:show_vpn_banner, show_vpn_banner)
    |> assign(:check_timezone, check_timezone)
    |> assign(:ip_location, ip_location)
    |> assign(:impersonating_staff_id, impersonating_staff_id)
    |> do_mount(%{}, session)
  end

  def mount(params, session, socket) do
    do_mount(socket, params, session)
  end

  @impl true
  def handle_event("search", %{"search_term" => search_term} = _params, socket) do
    socket
    |> SegmentAnalyticsHelpers.track_segment_event("Navbar Searched", %{
      search_term: search_term
    })
    |> push_navigate(to: Routes.live_path(socket, SearchLive, search_term))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:new_notification, _notification}, socket) do
    socket
    |> update(:unread_notifications, &(&1 + 1))
    |> then(&{:noreply, &1})
  end

  @spec do_mount(Socket.t(), map, map) :: {:ok, Socket.t()}
  defp do_mount(socket, _params, _session) do
    current_user = Map.get(socket.assigns, :current_user)

    if connected?(socket) and !!current_user do
      NotifyClient.subscribe_to_events_affecting(current_user)
    end

    socket
    |> assign(:display_name, if(current_user, do: current_user.display_name))
    |> assign(:avatar_url, if(current_user, do: Accounts.avatar_url(current_user)))
    |> assign(:user_email, if(current_user, do: Accounts.user_email(current_user)))
    |> assign(show_create_tournament_link: @show_create_tournament_link)
    |> assign_current_user_unread_notifications()
    |> then(&{:ok, &1})
  end

  defp assign_current_user_unread_notifications(%{assigns: %{current_user: nil}} = socket) do
    assign(socket, :unread_notifications, 0)
  end

  defp assign_current_user_unread_notifications(socket) do
    %{current_user: current_user} = socket.assigns

    Notifications.get_notifications_by(user_id: current_user.id, is_unread: true)
    |> Enum.count()
    |> then(&assign(socket, :unread_notifications, &1))
  end
end
