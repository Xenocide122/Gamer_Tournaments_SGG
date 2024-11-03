defmodule StridentWeb.TeamRostersLive.Show do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Accounts
  alias Strident.Games
  alias Strident.Teams
  alias Strident.Teams.TeamUserInvitation

  @name_blank "Roster name cannot be blank"

  on_mount(__MODULE__)

  def on_mount(
        :default,
        %{"slug" => slug},
        _session,
        %{assigns: %{current_user: current_user}} = socket
      ) do
    with %Teams.Team{} = team <-
           Teams.get_team_with_preloads_by([slug: slug],
             team_members: [user: :password_credential],
             team_rosters: [:game, [members: [team_member: :user]]]
           ),
         true <- Teams.is_user_member?(current_user, team) do
      socket
      |> assign(
        team: team,
        team_site: :rosters,
        can_edit: Teams.is_user_member?(current_user, team, :team_manager),
        games: Games.list_games(),
        new_roster_game: nil,
        new_roster_members: [],
        new_roster_name: nil,
        new_roster_name_error: @name_blank,
        invite_changeset: TeamUserInvitation.changeset(%TeamUserInvitation{}, %{}),
        invites: Teams.get_team_invites(team, :pending),
        open_roster_id: nil
      )
      |> then(&{:cont, &1})
    else
      _ -> {:halt, redirect(socket, to: Routes.live_path(socket, StridentWeb.HomeLive))}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Manage Rosters")}
  end

  @impl true
  def handle_event("open-roster", %{"roster" => roster_id}, socket) do
    {:noreply, assign(socket, :open_roster_id, roster_id)}
  end

  @impl true
  def handle_event(_, _, %{assigns: %{can_edit: false}} = socket) do
    {:noreply, put_flash(socket, :error, "You need to be a team manager to do that")}
  end

  @impl true
  def handle_event(
        "update-roster-member",
        %{"member" => member_id, "roster" => roster_id, "change" => change},
        %{assigns: %{team: %{team_rosters: rosters}, can_edit: true}} = socket
      ) do
    attrs =
      case change do
        "starter" -> %{is_starter: true}
        "sub" -> %{is_starter: false}
        "captain" -> %{type: :captain}
        "player" -> %{type: :player}
      end

    roster = Enum.find(rosters, &(&1.id == roster_id))
    member = Enum.find(roster.members, &(&1.id == member_id))

    if roster && member do
      case Teams.update_roster_member(member, attrs) do
        {:ok, updated_roster_member} ->
          updated_roster = update_roster_member(updated_roster_member, roster)

          {:noreply, update_roster(socket, updated_roster)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Could not modify roster member")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "remove-roster-member",
        %{"member" => member_id, "roster" => roster_id},
        %{assigns: %{team: %{team_rosters: rosters}, can_edit: true}} = socket
      ) do
    roster = Enum.find(rosters, &(&1.id == roster_id))
    member = Enum.find(roster.members, &(&1.id == member_id))

    if roster && member do
      case Teams.remove_roster_member(member) do
        {:ok, _} ->
          updated_roster = remove_roster_member(member, roster)
          {:noreply, update_roster(socket, updated_roster)}

        {:error, _changeset} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Could not remove the member from the roster. Please try again."
           )}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "validate-new-roster-name",
        %{"new_roster" => %{"roster_name" => name}},
        %{assigns: %{team: %{team_rosters: rosters}, can_edit: true}} = socket
      ) do
    {:noreply,
     assign(socket,
       new_roster_name: name,
       new_roster_name_error:
         cond do
           name == "" ->
             @name_blank

           Enum.any?(rosters, &(&1.slug == Slug.slugify(name))) ->
             "You have already used this roster name"

           true ->
             nil
         end
     )}
  end

  @impl true
  def handle_event(
        "set-game",
        %{"game" => game_id},
        %{assigns: %{games: games}} = socket
      ) do
    {:noreply, assign(socket, new_roster_game: Enum.find(games, &(&1.id == game_id)))}
  end

  @impl true
  def handle_event(
        "add-new-roster-member",
        %{"member" => member_id},
        %{
          assigns: %{
            team: %{team_members: members},
            new_roster_members: roster_members,
            can_edit: true
          }
        } = socket
      ) do
    team_member = Enum.find(members, &(&1.id == member_id))

    if team_member && not Enum.any?(roster_members, &(&1.team_member.id == member_id)) do
      roster_member = %Teams.TeamRosterMember{
        team_member: team_member,
        type: :player,
        is_starter: true
      }

      {:noreply, assign(socket, new_roster_members: [roster_member | roster_members])}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "update-new-roster-member",
        %{"member" => member_id, "change" => change},
        %{assigns: %{new_roster_members: roster_members, can_edit: true}} = socket
      ) do
    attrs =
      case change do
        "starter" -> %{is_starter: true}
        "sub" -> %{is_starter: false}
        "captain" -> %{type: :captain}
        "player" -> %{type: :player}
      end

    roster_members =
      Enum.map(roster_members, fn %{team_member: %{id: id}} = roster_member ->
        if id == member_id do
          Map.merge(roster_member, attrs)
        else
          roster_member
        end
      end)

    {:noreply, assign(socket, new_roster_members: roster_members)}
  end

  @impl true
  def handle_event(
        "remove-new-roster-member",
        %{"member" => member_id},
        %{assigns: %{new_roster_members: roster_members, can_edit: true}} = socket
      ) do
    updated_roster = Enum.reject(roster_members, &(&1.team_member.id == member_id))

    {:noreply, assign(socket, new_roster_members: updated_roster)}
  end

  @impl true
  def handle_event(
        "create-new-roster",
        %{"new_roster" => %{"roster_name" => name}},
        %{
          assigns: %{
            new_roster_members: roster_members,
            new_roster_game: game,
            team: team,
            can_edit: true
          }
        } = socket
      ) do
    case Teams.create_roster(%{team_id: team.id, game_id: game.id, name: name}, roster_members) do
      {:ok, result} ->
        socket =
          socket
          |> assign(
            team: %{team | team_rosters: [%{result | game: game} | team.team_rosters]},
            new_roster_name: nil,
            new_roster_name_error: @name_blank,
            new_roster_game: nil,
            new_roster_members: []
          )
          |> push_event("close-roster", %{})

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create roster")}
    end
  end

  @impl true
  def handle_event(
        "invite-user",
        %{"team_user_invitation" => %{"email" => email}},
        %{assigns: %{team: team, invites: invites, can_edit: true}} = socket
      ) do
    case Teams.create_user_invite(team, email) do
      {:ok, %{maybe_team_user_invitation_user: tuiu, team_user_invitation: tui}} ->
        tuiu =
          if tuiu,
            do: %{
              tuiu
              | user: Accounts.get_user_with_preloads_by(id: tuiu.user_id)
            },
            else: tuiu

        invites = [
          %{
            tui
            | team_user_invitation_user: tuiu
          }
          | invites
        ]

        {:noreply, assign(socket, invites: invites)}

      {:error, :team_user_invitation, changeset, _} ->
        {:noreply, assign(socket, invite_changeset: changeset)}
    end
  end

  @impl true
  def handle_event(
        "cancel-invite",
        %{"invitee" => invitee_id},
        %{assigns: %{invites: invites, can_edit: true}} = socket
      ) do
    invitee = Enum.find(invites, &(&1.id == invitee_id))

    if invitee do
      case Teams.change_invitation_status(invitee, :deleted) do
        {:ok, _} ->
          invites = Enum.reject(invites, &(&1.id == invitee_id))
          {:noreply, assign(socket, invites: invites)}

        _ ->
          {:noreply, put_flash(socket, :error, "Failed to cancel invite")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "remove-team-member",
        %{"member" => member_id},
        %{
          assigns: %{team: %{team_rosters: rosters, team_members: members} = team, can_edit: true}
        } = socket
      ) do
    member = Enum.find(members, &(&1.id == member_id))

    if member && member.type != :team_manager do
      case Teams.delete_team_member(member) do
        {:ok, _} ->
          rosters =
            Enum.map(rosters, fn %{members: members} = roster ->
              %{roster | members: Enum.reject(members, &(&1.team_member.id == member_id))}
            end)

          members = Enum.reject(members, &(&1.id == member_id))

          {:noreply, assign(socket, team: %{team | team_rosters: rosters, team_members: members})}

        _ ->
          {:noreply, put_flash(socket, :error, "Could not remove team member")}
      end
    else
      {:noreply, socket}
    end
  end

  defp remove_roster_member(to_remove, roster) do
    %{
      roster
      | members: Enum.reject(roster.members, &(&1.id == to_remove.id))
    }
  end

  defp update_roster_member(updated_roster_member, roster) do
    %{
      roster
      | members:
          Enum.map(roster.members, fn %{id: id} = roster_member ->
            if id == updated_roster_member.id,
              do: updated_roster_member,
              else: roster_member
          end)
    }
  end

  defp update_roster(socket, updated_roster) do
    update(socket, :team, fn %{team_rosters: rosters} = team ->
      %{
        team
        | team_rosters:
            Enum.map(rosters, fn %{id: id} = roster ->
              if id == updated_roster.id, do: updated_roster, else: roster
            end)
      }
    end)
  end
end
