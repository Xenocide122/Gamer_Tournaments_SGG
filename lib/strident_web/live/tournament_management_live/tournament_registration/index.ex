defmodule StridentWeb.TournamentRegistrationLive.Index do
  @moduledoc false
  use StridentWeb, :live_view

  import StridentWeb.TournamentRegistrationLive.Components.Page

  alias Strident.Parties
  alias Strident.Parties.Party
  alias Strident.Parties.PartyInvitation
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias Strident.Tournaments.TournamentInvitation
  alias StridentWeb.SegmentAnalyticsHelpers
  alias StridentWeb.TournamentRegistrationLive.Components.CreateRosterForm
  alias StridentWeb.TournamentRegistrationLive.Components.RegistrationComponent

  require Logger

  @team_pages [:create_roster, :registration]
  @individual_pages [:registration]
  @invite_pages [:accept]
  @tournament_preloads [:game, :registration_fields]

  @impl true
  def mount(%{"slug" => slug}, _, %{assigns: %{current_user: nil}} = socket) do
    user_return_to = Routes.live_path(socket, StridentWeb.TournamentRegistrationLive.Index, slug)

    redirect_to =
      Routes.live_path(socket, StridentWeb.UserLogInLive, %{user_return_to: user_return_to})

    socket
    |> redirect(to: redirect_to)
    |> then(&{:ok, &1})
  end

  def mount(_, _, socket) do
    pages = [:terms]

    socket
    |> assign(:terms_and_conditions, false)
    |> assign(pages: pages)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(%{"slug" => slug, "show" => "registration"}, _url, socket) do
    tournament = Tournaments.get_tournament_with_preloads_by([slug: slug], @tournament_preloads)

    socket
    |> update_pages_state(socket.assigns.pages, tournament, :from_wallet)
    |> assign(:invitation, nil)
    |> do_mount(tournament, slug)
    |> then(&{:noreply, &1})
  end

  def handle_params(%{"slug" => slug, "invitation" => invitation_id}, _url, socket) do
    with %Tournament{} = tournament <-
           Tournaments.get_tournament_with_preloads_by([slug: slug], @tournament_preloads),
         %TournamentInvitation{} = invitation <-
           Tournaments.get_invitation_with_preloads_by(id: invitation_id) do
      socket
      |> update_pages_state(socket.assigns.pages, tournament, :setup)
      |> assign(:invitation, invitation)
      |> do_mount(tournament, slug)
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> put_flash(:error, "Sorry, that invitation is invalid.")
        |> redirect(to: Routes.live_path(socket, StridentWeb.HomeLive))
        |> then(&{:noreply, &1})
    end
  end

  def handle_params(%{"slug" => slug, "party_invitation" => party_invitation_id}, _url, socket) do
    with %Tournament{id: tournament_id} = tournament <-
           Tournaments.get_tournament_with_preloads_by([slug: slug], @tournament_preloads),
         %PartyInvitation{
           status: invitation_status,
           party: %{tournament_participants: [%{tournament_id: ^tournament_id}]}
         } = invitation
         when invitation_status not in [nil, :dropped, :rejected] <-
           Parties.get_party_invitation_with_preloads_by(
             [id: party_invitation_id],
             party: [tournament_participants: []]
           ) do
      socket
      |> update_pages_state(socket.assigns.pages, tournament, :party_invite_setup)
      |> assign(:invitation, invitation)
      |> assign(party: invitation.party)
      |> do_mount(tournament, slug)
      |> then(&{:noreply, &1})
    else
      _error ->
        socket
        |> put_flash(:error, "Sorry, that invitation is invalid.")
        |> redirect(to: Routes.live_path(socket, StridentWeb.HomeLive))
        |> then(&{:noreply, &1})
    end
  end

  def handle_params(%{"slug" => slug}, _url, socket) do
    tournament = Tournaments.get_tournament_with_preloads_by([slug: slug], @tournament_preloads)

    socket
    |> update_pages_state(socket.assigns.pages, tournament, :setup)
    |> assign(:invitation, nil)
    |> do_mount(tournament, slug)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("cancel", %{"to" => return_to}, socket) do
    {:noreply, push_navigate(socket, to: "#{return_to}")}
  end

  def handle_event("next", %{"current_page" => current_page}, socket) do
    socket
    |> update_pages_state(socket.assigns.pages, socket.assigns.tournament, :next)
    |> assign(steps_completed: add_steps_completed(current_page, socket.assigns.steps_completed))
    |> then(&{:noreply, &1})
  end

  def handle_event("back", %{"current-page" => current_page}, socket) do
    socket
    |> go_back(current_page)
    |> then(&{:noreply, &1})
  end

  def handle_event("back", %{"current_page" => current_page}, socket) do
    socket
    |> go_back(current_page)
    |> then(&{:noreply, &1})
  end

  def handle_event("clicked-terms", _, socket) do
    socket
    |> toggle_terms()
    |> then(&{:noreply, &1})
  end

  def handle_event("accept-party-invitation", _, socket) do
    %{
      assigns: %{
        tournament: tournament,
        current_user: current_user,
        invitation: invitation
      }
    } = socket

    current_user_roster_invites =
      Strident.Rosters.get_users_roster_invites(tournament.id, current_user)

    case current_user_roster_invites
         |> Enum.split_with(&(&1.id == invitation.id))
         |> Parties.accept_and_reject_roster_invites_on_tournament(tournament.id, current_user) do
      {:ok, results} ->
        party_member =
          Enum.find(results, fn
            {{:party_member, _tp_id}, _party_member} -> true
            _ -> false
          end)
          |> elem(1)

        socket
        |> SegmentAnalyticsHelpers.track_segment_event("Joined Roster", %{
          tournament_id: tournament.id,
          game_title: tournament.game.title,
          party_id: party_member.party_id
        })
        |> push_navigate(to: Routes.tournament_show_pretty_path(socket, :show, tournament.slug))
        |> then(&{:noreply, &1})

      {:error, _, error, _} ->
        socket
        |> put_string_or_changeset_error_in_flash(error, exclude_field: true)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_info({:party, party_attrs, current_page, selected_users}, socket) do
    socket
    |> assign(party_attrs: party_attrs)
    |> assign(selected_users: selected_users)
    |> assign(:party_changeset, Parties.change_party(%Party{}, party_attrs))
    |> update_pages_state(socket.assigns.pages, socket.assigns.tournament, :next)
    |> assign(steps_completed: add_steps_completed(current_page, socket.assigns.steps_completed))
    |> then(&{:noreply, &1})
  end

  defp do_mount(socket, tournament, slug) do
    %{assigns: %{current_user: current_user}} = socket

    socket
    |> assign(tournament: tournament)
    |> assign(steps_completed: [])
    |> assign(party_changeset: changeset_with_team_manager(tournament, current_user))
    |> assign(party_attrs: initial_params(tournament, current_user))
    |> assign(selected_users: [current_user])
    |> assign(return_to: "/t/#{slug}")
  end

  defp changeset_with_team_manager(tournament, current_user) do
    Parties.change_party(%Party{}, initial_params(tournament, current_user))
  end

  defp initial_params(tournament, current_user) do
    %{
      "name" => "",
      "email" => current_user.email,
      "party_invitations" => party_invitations(tournament, current_user),
      "party_members" => manager_params(current_user)
    }
  end

  defp party_invitations(%{players_per_participant: players_per_participant}, current_user) do
    party_invitations = %{
      "0" => %{
        "user_id" => current_user.id,
        "status" => "accepted"
      }
    }

    for idx <- 1..(players_per_participant - 1)//1, reduce: party_invitations do
      party_invitations ->
        Map.put(party_invitations, "#{idx}", %{"email" => ""})
    end
  end

  defp manager_params(current_user) do
    %{
      "0" => %{
        "type" => "manager",
        "user_id" => current_user.id
      }
    }
  end

  defp toggle_terms(%{assigns: %{terms_and_conditions: true}} = socket),
    do: assign(socket, terms_and_conditions: false)

  defp toggle_terms(%{assigns: %{terms_and_conditions: false}} = socket),
    do: assign(socket, terms_and_conditions: true)

  defp add_steps_completed(current_page, steps_completed) do
    Enum.uniq([String.to_existing_atom(current_page) | steps_completed])
  end

  defp remove_steps_completed(current_page, steps_completed) do
    Enum.filter(steps_completed, &(&1 != String.to_existing_atom(current_page)))
  end

  defp update_pages_state(
         %{assigns: %{current_page: current_page}} = socket,
         pages,
         _tournament,
         :next
       )
       when is_list(pages) do
    next = next(pages, current_page)

    socket
    |> assign(current_page: next)
    |> assign(previous: current_page)
    |> assign(next: next(pages, next))
  end

  defp update_pages_state(
         %{assigns: %{current_page: current_page}} = socket,
         pages,
         _tournament,
         :back
       )
       when is_list(pages) do
    previous = previous(pages, current_page)

    socket
    |> assign(current_page: previous)
    |> assign(previous: previous(pages, previous))
    |> assign(next: current_page)
  end

  defp update_pages_state(socket, pages, tournament, :setup)
       when is_list(pages) do
    pages = update_based_on_players_per_participant(socket, pages, tournament)

    current_page = List.first(pages)

    socket
    |> assign(pages: pages)
    |> assign(current_page: current_page)
    |> assign(next: next(pages, current_page))
    |> assign(previous: previous(pages, current_page))
  end

  defp update_pages_state(socket, pages, tournament, :party_invite_setup)
       when is_list(pages) do
    pages = update_pages_for_party_invite(socket, pages, tournament)

    current_page = List.first(pages)

    socket
    |> assign(pages: pages)
    |> assign(current_page: current_page)
    |> assign(next: next(pages, current_page))
    |> assign(previous: previous(pages, current_page))
  end

  defp update_pages_state(socket, pages, tournament, :from_wallet)
       when is_list(pages) do
    pages = update_based_on_players_per_participant(socket, pages, tournament)

    current_page =
      if tournament.players_per_participant > 1, do: :team_registration, else: :registration

    socket
    |> assign(pages: pages)
    |> assign(current_page: current_page)
    |> assign(next: next(pages, current_page))
    |> assign(previous: previous(pages, current_page))
  end

  defp go_back(socket, current_page) do
    socket
    |> update_pages_state(socket.assigns.pages, socket.assigns.tournament, :back)
    |> assign(
      steps_completed: remove_steps_completed(current_page, socket.assigns.steps_completed)
    )
  end

  defp update_based_on_players_per_participant(
         _socket,
         pages,
         %{players_per_participant: players_per_participant}
       ) do
    pages
    |> update_based_on_players_per_participant(players_per_participant)
  end

  defp update_based_on_players_per_participant(pages, players_per_participant)
       when players_per_participant > 1 do
    [pages | @team_pages] |> List.flatten()
  end

  defp update_based_on_players_per_participant(pages, _players_per_participant) do
    [pages | @individual_pages] |> List.flatten()
  end

  defp update_pages_for_party_invite(_socket, pages, _tournament) do
    pages
    |> update_for_invitations()
  end

  defp update_for_invitations(pages) do
    [pages | @invite_pages] |> List.flatten()
  end

  defp previous(pages, current_page) do
    Enum.reverse(pages)
    |> next(current_page)
  end

  defp next([], _), do: nil
  defp next([page], current_page) when page == current_page, do: nil
  defp next([page, next | _t], current_page) when page == current_page, do: next

  defp next([_h | t], current_page) do
    next(t, current_page)
  end
end
