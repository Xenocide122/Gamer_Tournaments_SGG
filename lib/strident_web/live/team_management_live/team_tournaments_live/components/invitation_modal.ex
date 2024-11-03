defmodule StridentWeb.TeamTournamentsLive.Components.InvitationModal do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Teams

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{invitation: invitation, tournament: tournament, team: team} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:invitation, invitation)
    |> assign(:tournament, tournament)
    |> assign(:team, team)
    |> assign(:stake_percentage, get_mininum_split_stake(tournament))
    |> assign(:open_terms_and_condition, false)
    |> assign(:consent, false)
    |> assign_search_term()
    |> assign_search_results()
    |> assign_selected_roster()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("click-away", _params, socket) do
    socket
    |> assign_search_term()
    |> assign_search_results()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("search", %{"value" => search_term}, socket)
      when byte_size(search_term) < 3 do
    {:noreply, assign_search_term(socket, search_term)}
  end

  @impl true
  def handle_event(
        "search",
        %{"value" => search_term},
        %{assigns: %{team: team, selected_roster: selected_roster}} = socket
      ) do
    socket =
      socket
      |> assign_search_term(search_term)
      |> assign_search_results(
        team.team_members
        |> Enum.reduce([], fn %{user: user}, users ->
          if String.downcase(user.display_name) =~ String.downcase(search_term) and
               user not in selected_roster do
            [user | users]
          else
            users
          end
        end)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("pick", %{"id" => user_id}, %{assigns: %{team: team}} = socket) do
    team_member = Enum.find(team.team_members, fn %{user: user} -> user.id == user_id end)

    socket
    |> add_roster_member(Map.put(team_member.user, :member_type, team_member.type))
    |> assign_search_term()
    |> assign_search_results()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove", %{"item" => item_id}, socket) do
    socket
    |> update(:selected_roster, fn roster ->
      Enum.reject(roster, &(&1.id == item_id))
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "validate-participant-stake",
        %{"new_roster" => %{"stake_percentage" => percentage}},
        socket
      ) do
    {:noreply, assign(socket, :stake_percentage, percentage)}
  end

  @impl true
  def handle_event("open-consent", _params, socket) do
    {:noreply, assign(socket, :open_terms_and_condition, true)}
  end

  @impl true
  def handle_event(
        "terms-and-condition-consent",
        %{"terms_and_condition" => %{"consent" => "true"}},
        socket
      ) do
    {:noreply, assign(socket, :consent, true)}
  end

  @impl true
  def handle_event(
        "terms-and-condition-consent",
        %{"terms_and_condition" => %{"consent" => "false"}},
        socket
      ) do
    {:noreply, assign(socket, :consent, false)}
  end

  @impl true
  def handle_event(
        "accept-invitation",
        _params,
        %{
          assigns: %{
            team: team,
            invitation: invitation,
            stake_percentage: stake_percentage,
            selected_roster: selected_roster
          }
        } = socket
      ) do
    case Teams.update_status_on_tournament_invitation(invitation, team, :accepted,
           players: selected_roster,
           stake_split: Decimal.div(stake_percentage, 100)
         ) do
      {:ok, _invitation} ->
        send(self(), {:invitation_accepted, %{id: invitation.id}})
        {:noreply, socket}

      _ ->
        socket
        |> put_flash(
          :error,
          "There is a problem with accepting this invitation. Please contact the tournament organizer."
        )
        |> then(&{:noreply, &1})
    end
  end

  def assign_search_results(socket, search_results \\ []) do
    assign(socket, :search_results, search_results)
  end

  def assign_search_term(socket, search_term \\ "") do
    assign(socket, :search_term, search_term)
  end

  def add_roster_member(socket, team_member) do
    update(socket, :selected_roster, fn roster -> [team_member | roster] end)
  end

  def assign_selected_roster(%{assigns: %{team: team}} = socket) do
    team.team_members
    |> Enum.map(fn
      %{type: type, user: user} when type in [:player, :captain, :substitute, :coach] ->
        Map.put(user, :member_type, type)

      %{user: user} ->
        Map.put(user, :member_type, :player)
    end)
    |> then(&assign(socket, :selected_roster, &1))
  end

  def get_mininum_split_stake(_tournament) do
    0
  end
end
