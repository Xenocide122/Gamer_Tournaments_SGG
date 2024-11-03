defmodule StridentWeb.TeamManagment.Setup do
  @moduledoc false
  import Phoenix.LiveView
  import Phoenix.Component
  alias Strident.Teams
  alias Strident.Teams.Team
  alias StridentWeb.Router.Helpers, as: Routes

  def on_mount(_, _, _, %{assigns: %{current_user: nil}} = socket) do
    socket
    |> redirect(to: Routes.live_path(socket, StridentWeb.UserLogInLive))
    |> then(&{:halt, &1})
  end

  def on_mount(
        :default,
        %{"slug" => slug},
        _session,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    with(
      %Team{} = team <-
        Teams.get_team_with_preloads_by([slug: slug],
          social_media_links: [],
          team_members: :user,
          team_rosters: [game: [], members: [team_member: :user]]
        ),
      true <-
        Teams.can_user_edit?(current_user, team) or
          Teams.is_user_team_manager?(current_user, team)
    ) do
      socket
      |> assign(%{team: team})
      |> assign(logo_url: Teams.get_team_image(team))
      |> then(&{:cont, &1})
    else
      _ ->
        socket
        |> put_flash(
          :info,
          "You must be a Team Captain or Team Manager to access the settings page"
        )
        |> redirect(to: Routes.live_path(socket, StridentWeb.TeamProfileLive.Show, slug))
        |> then(&{:halt, &1})
    end
  end
end
