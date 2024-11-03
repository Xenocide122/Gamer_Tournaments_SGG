defmodule StridentWeb.Components.Profile.Card do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.Teams
  alias Strident.Teams.Team
  alias StridentWeb.TeamProfileLive

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{profile: profile} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign_profile(profile)
    |> assign_login_link()
    |> assign_profile_url()
    |> assign_logo_url()
    |> assign_display_name()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("follow", _params, socket) do
    socket
    |> follow()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("unfollow", _params, socket) do
    socket
    |> unfollow()
    |> then(&{:noreply, &1})
  end

  @spec follow(Socket.t()) :: Socket.t()
  defp follow(%{assigns: %{current_user: current_user, profile: %User{} = user}} = socket) do
    case Accounts.follow_user(user.id, current_user.id) do
      {:ok, _follow} ->
        update(socket, :profile, fn user -> %{user | current_user_follows: true} end)

      _ ->
        put_flash(socket, :error, "Cannot follow user")
    end
  end

  defp follow(%{assigns: %{current_user: current_user, profile: %Team{} = team}} = socket) do
    case Teams.follow_team(team.id, current_user.id) do
      {:ok, _follow} ->
        update(socket, :profile, fn team -> %{team | current_user_follows: true} end)

      _ ->
        put_flash(socket, :error, "Cannot follow team")
    end
  end

  @spec unfollow(Socket.t()) :: Socket.t()
  defp unfollow(%{assigns: %{current_user: current_user, profile: %User{} = user}} = socket) do
    case Accounts.unfollow_user(user.id, current_user.id) do
      {:ok, _unfollow} ->
        update(socket, :profile, fn user -> %{user | current_user_follows: false} end)

      _ ->
        put_flash(socket, :error, "Cannot unfollow user")
    end
  end

  defp unfollow(%{assigns: %{current_user: current_user, profile: %Team{} = team}} = socket) do
    case Teams.unfollow_team(team.id, current_user.id) do
      {:ok, _unfollow} ->
        update(socket, :profile, fn team -> %{team | current_user_follows: false} end)

      _ ->
        put_flash(socket, :error, "Cannot unfollow team")
    end
  end

  defp show_buttons(%{current_user: %User{id: id}, profile: %{id: id}} = assigns) do
    ~H"""

    """
  end

  defp show_buttons(%{current_user: %User{}, profile: %{current_user_follows: true}} = assigns) do
    ~H"""
    <button
      class="px-2 text-sm border rounded border-grey-light text-grey-light"
      phx-click="unfollow"
      phx-target={@myself}
    >
      Following
    </button>
    """
  end

  defp show_buttons(%{current_user: %User{}, profile: %{current_user_follows: false}} = assigns) do
    ~H"""
    <button
      class="px-4 text-sm border rounded btn--primary-ghost"
      phx-click="follow"
      phx-target={@myself}
    >
      Follow
    </button>
    """
  end

  defp show_buttons(%{current_user: %User{}} = assigns) do
    # Handle also when from the view profile is send without following key-value
    ~H"""
    <button
      class="px-4 text-sm border rounded btn--primary-ghost"
      phx-click="follow"
      phx-target={@myself}
    >
      Follow
    </button>
    """
  end

  defp show_buttons(assigns) do
    ~H"""
    <.link navigate={@login_link} class="btn--primary-ghost text-sm border rounded px-4 py-2">
      Login
    </.link>
    """
  end

  defp assign_profile(socket, profile) do
    assign(socket, :profile, profile)
  end

  defp assign_login_link(socket) do
    assign(socket, :login_link, Routes.live_path(socket, StridentWeb.UserLogInLive))
  end

  defp assign_profile_url(%{assigns: %{profile: profile}} = socket) do
    profile_url =
      case profile do
        %Team{} = team ->
          Routes.live_path(socket, TeamProfileLive.Show, team.slug)

        %User{slug: slug} when is_binary(slug) ->
          Routes.user_show_path(socket, :show, slug)

        _ ->
          nil
      end

    assign(socket, :profile_url, profile_url)
  end

  defp assign_logo_url(%{assigns: %{profile: %Team{} = profile}} = socket) do
    assign(socket, :logo_url, profile.logo_url)
  end

  defp assign_logo_url(socket) do
    assign(socket, :logo_url, Accounts.avatar_url(socket.assigns.profile))
  end

  defp assign_display_name(%{assigns: %{profile: %Team{} = profile}} = socket) do
    assign(socket, :display_name, profile.name)
  end

  defp assign_display_name(%{assigns: %{profile: profile}} = socket) do
    assign(socket, :display_name, Accounts.get_user_name(profile))
  end
end
