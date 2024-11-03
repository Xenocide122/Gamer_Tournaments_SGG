defmodule StridentWeb.TeamTournamentsLive.Show do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Teams

  on_mount(StridentWeb.TeamManagment.Setup)

  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    {:ok, assign_socket(socket, slug, params)}
  end

  @impl true
  def handle_event(
        "decline-invitation",
        %{"invitation" => invitation_id},
        %{assigns: %{tournament_invitations: tournament_invitations, team: team}} = socket
      ) do
    invitation = Enum.find(tournament_invitations, fn %{id: id} -> invitation_id == id end)

    case Teams.update_status_on_tournament_invitation(invitation, team, :rejected) do
      {:ok, _invitation} ->
        socket
        |> update(
          :tournament_invitations,
          &Enum.reject(&1, fn %{id: id} -> invitation_id == id end)
        )
        |> put_flash(
          :info,
          "You have successfully declined this invitation. We will notify the organizer."
        )
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "Unable to reject this invitation. Please try again.")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("open-invitation", %{"invitation" => invitation_id}, socket) do
    send_update(StridentWeb.TeamTournamentsLive.Components.InvitationCard,
      id: "tournament-invitation-#{invitation_id}",
      open_invitation: true
    )

    {:noreply, assign(socket, :open_invitation, true)}
  end

  @impl true
  def handle_event("close-invitation", %{"invitation" => invitation_id}, socket) do
    send_update(StridentWeb.TeamTournamentsLive.Components.InvitationCard,
      id: "tournament-invitation-#{invitation_id}",
      close_invitation: true
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("open-tournament-participant", %{"tournament" => tournament_id}, socket) do
    send_update(StridentWeb.TeamTournamentsLive.Components.TournamentCard,
      id: "tournament-live-#{tournament_id}",
      open_modal: true
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("close-tournament-participant", %{"tournament" => tournament_id}, socket) do
    send_update(StridentWeb.TeamTournamentsLive.Components.TournamentCard,
      id: "tournament-live-#{tournament_id}",
      open_modal: false
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:invitation_accepted, %{id: invitation_id}},
        %{assigns: %{tournament_invitations: tournament_invitations}} = socket
      ) do
    invitation = Enum.find(tournament_invitations, fn %{id: id} -> invitation_id == id end)

    send_update(StridentWeb.TeamTournamentsLive.Components.TournamentCard,
      id: "tournament-invitation-#{invitation_id}",
      close_invitation: true
    )

    socket
    |> update(
      :tournament_invitations,
      &Enum.reject(&1, fn %{id: id} -> invitation_id == id end)
    )
    |> update(:competing_tournaments, fn tournaments ->
      [invitation.tournament | tournaments]
    end)
    |> put_flash(:info, "Successfully accepted this invitation!")
    |> then(&{:noreply, &1})
  end

  def assign_socket(socket, _slug, _params) do
    socket
    |> assign(:team_site, :tournaments)
    |> assign_page_title()
    |> assign_team_competing_tournaments()
    |> assign_team_tournament_invitations()
  end

  defp assign_page_title(%{assigns: %{team: team}} = socket) do
    assign(socket, page_title: "#{team.name}'s Tournaments")
  end

  def assign_team_competing_tournaments(%{assigns: %{team: team}} = socket) do
    assign(socket, :competing_tournaments, Teams.list_teams_tournaments_with_statuses(team))
  end

  def assign_team_tournament_invitations(%{assigns: %{team: team}} = socket) do
    assign(socket, :tournament_invitations, Teams.list_teams_tournament_invitations(team))
  end
end
