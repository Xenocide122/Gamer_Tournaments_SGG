defmodule StridentWeb.TeamProfileLive.Show do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.Teams
  alias Strident.Tournaments

  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    type =
      case params do
        %{"type" => "followers"} -> :followers
        _ -> :statistic
      end

    {:ok, assign_socket(socket, slug, type)}
  end

  @impl true
  def handle_params(%{"roster_slug" => game, "slug" => team}, _URI, socket) do
    {:noreply, assign(socket, slug: team, roster: game)}
  end

  @impl true
  def handle_params(%{"slug" => team}, _URI, socket) do
    {:noreply, assign(socket, slug: team, roster: nil)}
  end

  @impl true
  def handle_info({:team_updated, updates}, socket) do
    {:noreply, update(socket, :team, fn team -> Map.merge(team, updates) end)}
  end

  @impl true
  def handle_event("select-roster", %{"roster" => %{"roster" => ""}}, socket) do
    {:noreply,
     push_patch(socket,
       to: Routes.live_path(socket, StridentWeb.TeamProfileLive.Show, socket.assigns.team.slug)
     )}
  end

  @impl true
  def handle_event("select-roster", %{"roster" => %{"roster" => roster_slug}}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           StridentWeb.TeamProfileLive.Show,
           socket.assigns.team.slug,
           roster_slug
         )
     )}
  end

  @impl true
  def handle_event("follow", _value, socket) do
    {:noreply, follow_action(socket)}
  end

  @impl true
  def handle_event("unfollow", _value, socket) do
    {:noreply, unfollow_action(socket)}
  end

  @impl true
  def handle_event("open-followers", _params, %{assigns: %{followers_open_to: open_to}} = socket) do
    socket =
      socket
      |> assign(:show, :followers)
      |> push_patch(to: open_to)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open-statistic", _params, %{assigns: %{team: team}} = socket) do
    socket =
      socket
      |> assign(:show, :statistic)
      |> push_patch(to: Routes.live_path(socket, StridentWeb.TeamProfileLive.Show, team.slug))

    {:noreply, socket}
  end

  def assign_socket(socket, slug, type) do
    case Teams.get_team_with_preloads_by([slug: slug], [
           :social_media_links,
           followers: :followers,
           team_members: :user,
           team_rosters: [:game, :members]
         ]) do
      nil ->
        socket
        |> put_flash(:error, "Could not find team with name: #{inspect(slug)}")
        |> redirect(to: "/")

      %Teams.Team{} = team ->
        socket
        |> assign(:team, team)
        |> assign(:team_site, :profile)
        |> assign(
          rosters:
            Enum.map(team.team_rosters, fn %{name: name, slug: slug} ->
              {name, slug}
            end)
        )
        |> assign_page_title()
        |> assign_if_current_user_follows_team()
        |> assign_if_current_user_is_captain()
        |> assign_tournaments()
        |> assign_recent_tournament_results()
        |> assign(:show, type)
        |> assign_followers()
        |> assign_followers_open_to()
    end
  end

  def assign_page_title(%{assigns: %{team: team}} = socket) do
    assign(socket, page_title: team.name)
  end

  def assign_if_current_user_is_captain(
        %{assigns: %{team: team, current_user: current_user}} = socket
      ) do
    assign(socket, :can_edit, Teams.can_user_edit?(current_user, team))
  end

  def assign_achievements(%{assigns: %{team: team}} = socket) do
    assign(socket, :achievements, Tournaments.get_team_achivements(team))
  end

  def assign_tournaments(%{assigns: %{team: team}} = socket) do
    assign(socket, tournaments: Tournaments.list_team_tournaments(team))
  end

  def assign_recent_tournament_results(%{assigns: %{team: team}} = socket) do
    assign(socket,
      recent_results: Tournaments.get_team_recent_results(team, pagination: %{limit: 4})
    )
  end

  def assign_if_current_user_follows_team(
        %{assigns: %{team: team, current_user: current_user}} = socket
      ) do
    assign(socket, :following_team, follows?(current_user, team))
  end

  def assign_followers(
        %{assigns: %{team: %{followers: followers}, current_user: current_user}} = socket
      ) do
    followers =
      Enum.map(followers, fn %User{followers: followers} = follower ->
        Map.put(follower, :following, user_follows_profile(current_user, followers))
      end)

    assign(socket, :followers, followers)
  end

  def assign_followers_open_to(%{assigns: %{team: team}} = socket) do
    assign(socket, :followers_open_to, Routes.team_followers_path(socket, :show, team.slug))
  end

  defp follows?(nil, _user), do: false

  defp follows?(current_user, %Teams.Team{} = team) do
    Teams.user_follows_team?(current_user, team)
  end

  defp follows?(current_user, %{user: %User{} = user}) do
    Accounts.user_follows_user?(current_user, user)
  end

  defp user_follows_profile(nil, _followers) do
    false
  end

  defp user_follows_profile(current_user, followers) do
    current_user.id in Enum.map(followers, & &1.id)
  end

  defp follow_action(%{assigns: %{current_user: nil}} = socket),
    do: put_flash(socket, :error, "Please log in to follow this team.")

  defp follow_action(%{assigns: %{current_user: %User{} = user, team: team}} = socket) do
    case Teams.follow_team(team.id, user.id) do
      {:ok, _followed_team} ->
        Segment.Analytics.track(user.id, "Team Followed", %{team_id: team.id})
        assign(socket, :following_team, true)

      _ ->
        put_flash(socket, :error, "Cannot follow team")
    end
  end

  defp unfollow_action(%{assigns: %{current_user: nil}} = socket),
    do: put_flash(socket, :error, "Please log in to unfollow a team.")

  defp unfollow_action(%{assigns: %{current_user: %User{} = user, team: team}} = socket) do
    case Teams.unfollow_team(team.id, user.id) do
      {:ok, _unfollowed_team} ->
        Segment.Analytics.track(user.id, "Team Unfollowed", %{team_id: team.id})
        assign(socket, :following_team, false)

      _ ->
        put_flash(socket, :error, "Cannot unfollow team")
    end
  end

  defp upcoming_tournaments(tournaments) do
    Enum.filter(
      tournaments,
      &(&1.status in [:scheduled, :registrations_open, :in_progress, :registrations_closed])
    )
    |> Enum.take(3)
  end
end
