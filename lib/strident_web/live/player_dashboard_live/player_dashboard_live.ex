defmodule StridentWeb.PlayerDashboardLive do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Accounts.User
  alias Strident.Matches
  alias Strident.MatchReports
  alias Strident.Parties
  alias Strident.Parties.Party
  alias Strident.Repo
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias Strident.Tournaments.TournamentParticipant
  alias Strident.UrlGeneration
  alias StridentWeb.Router.Helpers, as: Routes

  @participant_preloads [
    :active_invitation,
    players: [user: []],
    team: [team_members: :user],
    party: [party_members: :user]
  ]

  @tournament_preloads [
    :game,
    :social_media_links,
    :created_by,
    stages: [
      :settings,
      :child_edges,
      :children,
      :participants,
      matches: [
        :parent_edges,
        participants: [tournament_participant: @participant_preloads]
      ]
    ],
    participants: @participant_preloads
  ]

  @impl true
  def mount(params, session, socket) do
    socket
    |> do_mount(params, session)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("drop-party-member", %{"id" => id}, socket) do
    %{my_party_member: my_party_member, party: party, tournament: tournament} = socket.assigns

    with true <- my_party_member.id == id,
         {:ok, _party_member} <- Parties.drop_party_member(id) do
      socket
      |> put_flash(:info, "You were successuflly removed from #{party.name}")
      |> push_navigate(to: Routes.tournament_show_pretty_path(socket, :show, tournament.slug))
    else
      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)

      _ ->
        put_flash(socket, :error, "You can't drop this user")
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "drop-and-refund",
        _params,
        %{assigns: %{current_user_can_manage_ids: false}} = socket
      ) do
    socket
    |> put_flash(:error, "You can't drop participant.")
    |> then(&{:noreply, &1})
  end

  def handle_event(
        "drop-and-refund",
        _params,
        %{assigns: %{tournament_participant: nil}} = socket
      ) do
    socket
    |> put_flash(:error, "You can't drop participant.")
    |> then(&{:noreply, &1})
  end

  def handle_event("drop-and-refund", %{"participant" => participant_id}, socket) do
    %{tournament_participant: participant, tournament: tournament} = socket.assigns

    with true <- participant.id == participant_id,
         {:ok, _, _} <-
           Tournaments.drop_tournament_participant_from_tournament(participant,
             refund_participant: true,
             notify_to_and_admins: true
           ) do
      socket
      |> put_flash(:info, "You've dropped from the tournament.")
      |> push_navigate(to: ~p"/t/#{tournament.slug}")
    else
      false ->
        put_flash(socket, :error, "You can't drop participant.")

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
    |> then(&{:noreply, &1})
  end

  defp do_mount(socket, params, _session) do
    %{"slug" => tournament_slug} = params
    %{current_user: current_user} = socket.assigns

    tournament =
      Tournaments.get_tournament_with_preloads_by([slug: tournament_slug], @tournament_preloads)

    socket
    |> assign(:tournament, tournament)
    |> assign(
      :can_manage_tournament,
      Tournaments.can_manage_tournament?(current_user, tournament)
    )
    |> assign(:team_site, :player_dashboard)
    |> assign(:current_user, current_user)
    |> assign_current_user_participant()
    |> assign_tournament_link()
    |> assign_tournament_discord_link()
    |> assign_next_match()
    |> assign_show_check_in_component()
    |> assign_show_report_score_component()
    |> maybe_assign_party()
    |> assign_show_challenge_component()
    |> assign_entry_fee_progress()
    |> assign_my_contribution_link()
    |> assign_my_party_member()
    |> maybe_handle_404()
  end

  defp assign_my_party_member(%{assigns: %{tournament_participant: nil}} = socket) do
    assign(socket, :my_party_member, nil)
  end

  defp assign_my_party_member(%{assigns: %{party: nil}} = socket) do
    assign(socket, :my_party_member, nil)
  end

  defp assign_my_party_member(socket) do
    %{party: party, current_user: current_user} = socket.assigns

    party.party_members
    |> Enum.find(&(&1.user_id == current_user.id))
    |> then(&assign(socket, :my_party_member, &1))
  end

  @spec maybe_handle_404(Socket.t()) :: Socket.t()
  defp maybe_handle_404(%{assigns: %{tournament_participant: nil}} = socket) do
    %{tournament: tournament} = socket.assigns

    socket
    |> put_flash(:error, "You are not participant on this tournament.")
    |> push_navigate(to: Routes.tournament_show_pretty_path(socket, :show, tournament.slug))
  end

  defp maybe_handle_404(socket), do: socket

  def assign_entry_fee_progress(%{assigns: %{tournament_participant: nil}} = socket) do
    assign(socket, :entry_fee_progress, 0)
  end

  def assign_entry_fee_progress(socket) do
    %{assigns: %{tournament_participant: participant, tournament: tournament}} = socket

    tournament.buy_in_amount
    |> TournamentParticipants.entry_fee_progression(participant)
    |> then(&assign(socket, :entry_fee_progress, &1))
  end

  def assign_my_contribution_link(%{assigns: %{tournament_participant: nil}} = socket) do
    assign(socket, :my_contribution_link, nil)
  end

  def assign_my_contribution_link(socket) do
    %{tournament: tournament, tournament_participant: participant} = socket.assigns

    case participant.status do
      :confirmed ->
        nil

      _ ->
        participant_slug =
          Tournaments.get_slug_for_go_stake_me(participant, tournament.players_per_participant)

        StridentWeb.Endpoint
        |> Routes.live_path(StridentWeb.GoStakeMeLive, tournament.slug, participant_slug)
        |> UrlGeneration.absolute_path()
    end
    |> then(&assign(socket, :my_contribution_link, &1))
  end

  def assign_tournament_link(socket) do
    %{assigns: %{tournament: tournament}} = socket

    StridentWeb.Endpoint
    |> Routes.tournament_show_path(:show, tournament)
    |> UrlGeneration.absolute_path()
    |> then(&assign(socket, :tournament_link, &1))
  end

  def assign_tournament_discord_link(socket) do
    %{tournament: tournament} = socket.assigns
    %{social_media_links: social_media_links} = Repo.preload(tournament, :social_media_links)

    social_media_links
    |> Enum.filter(&(&1.brand == :discord))
    |> Enum.at(0)
    |> then(fn
      nil -> nil
      link -> SocialMediaLink.add_user_input(link)
    end)
    |> then(&assign(socket, :tournament_discord_link, &1))
  end

  defp assign_next_match(%{assigns: %{tournament_participant: nil}} = socket) do
    assign(socket, :next_match, nil)
  end

  defp assign_next_match(socket) do
    %{tournament: tournament, tournament_participant: participant} = socket.assigns

    next_match =
      participant
      |> TournamentParticipants.next_match(tournament)
      |> Matches.get_match_with_preloads(
        stage: [],
        chat: [
          messages: [],
          match: [participants: [tournament_participant: [players: [user: []]]]]
        ]
      )

    assign(socket, :next_match, next_match)
  end

  def assign_current_user_participant(socket) do
    %{tournament: tournament, current_user: current_user} = socket.assigns

    tournament.participants
    |> Enum.reduce_while(nil, fn
      participant, nil ->
        if Enum.any?(participant.players, &(&1.user_id == current_user.id)) and
             participant.status != :dropped do
          {:halt, participant}
        else
          {:cont, nil}
        end
    end)
    |> then(&assign(socket, :tournament_participant, &1))
  end

  def assign_show_check_in_component(%{assigns: %{tournament_participant: nil}} = socket) do
    assign(socket, :show_check_in_component, false)
  end

  def assign_show_check_in_component(socket) do
    %{tournament_participant: tournament_participant} = socket.assigns
    assign(socket, :show_check_in_component, not tournament_participant.checked_in)
  end

  def assign_show_report_score_component(
        %{assigns: %{tournament_participant: nil, next_match: nil}} = socket
      ) do
    assign(socket, :show_report_score_component, false)
  end

  def assign_show_report_score_component(socket) do
    %{tournament_participant: tp, tournament: tournament, next_match: match} = socket.assigns

    %{tp | tournament: tournament}
    |> MatchReports.should_report_score?()
    |> then(fn show_report_score_compontent ->
      case match do
        nil -> show_report_score_compontent
        %{stage: %{type: :battle_royale}} -> false
        %{stage: %{type: _}} -> show_report_score_compontent
      end
    end)
    |> then(&assign(socket, :show_report_score_component, &1))
  end

  defp assign_show_challenge_component(%{assigns: %{tournament_participant: nil}} = socket) do
    assign(socket, :show_challenge_component, false)
  end

  defp assign_show_challenge_component(socket) do
    %{tournament: tournament, tournament_participant: tournament_participant} = socket.assigns

    assign(
      socket,
      :show_challenge_component,
      tournament_participant.checked_in and tournament.allow_wager
    )
  end

  def maybe_assign_party(socket) do
    %{tournament: %{players_per_participant: players_per_participant}} = socket.assigns

    party =
      if players_per_participant > 1 do
        %{assigns: %{tournament: tournament, current_user: current_user}} = socket

        party_members =
          Parties.list_party_members_with_preloads_by(
            [user_id: current_user.id],
            party: [:tournament_participants, :party_invitations, party_members: [:user]]
          )

        tournament_parties_for_current_user =
          for party_member <- party_members,
              participant <- party_member.party.tournament_participants,
              participant.status != :dropped,
              participant.tournament_id == tournament.id do
            party_member.party
          end

        case tournament_parties_for_current_user do
          [party] -> party
          _ -> nil
        end
      else
        nil
      end

    assign(socket, party: party)
  end

  @spec show_manage_roster?(Party.t(), User.t(), Tournament.t()) :: boolean()
  defp show_manage_roster?(party, user, tournament) do
    if is_manager_or_captain_of_party?(party, user) and can_manage_roster?(tournament),
      do: true,
      else: false
  end

  @spec show_manage_payouts?(TournamentParticipant.t(), Party.t(), User.t(), Tournament.t()) ::
          boolean()
  defp show_manage_payouts?(participant, party, user, tournament) do
    if is_manager_or_captain_of_party?(party, user) and
         is_tournament_finished?(tournament) and
         is_a_winner?(participant, tournament),
       do: true,
       else: false
  end

  @spec is_manager_or_captain_of_party?(Party.t(), User.t()) :: boolean()
  defp is_manager_or_captain_of_party?(party, user) do
    case Enum.find(party.party_members, &(&1.user_id == user.id)) do
      %{type: :manager} -> true
      %{type: :captain} -> true
      _ -> false
    end
  end

  @spec can_manage_roster?(Tournament.t()) :: boolean()
  defp can_manage_roster?(%{status: status})
       when status not in [:finished, :under_review, :cancelled],
       do: true

  defp can_manage_roster?(_), do: false

  @spec is_tournament_finished?(Tournament.t()) :: boolean()
  defp is_tournament_finished?(%{status: :finished}), do: true
  defp is_tournament_finished?(_), do: false

  @spec is_a_winner?(TournamentParticipant.t(), Tournament.t()) :: boolean()
  defp is_a_winner?(%{rank: nil}, _tournament), do: false

  defp is_a_winner?(%{rank: rank}, tournament) do
    prize_pool =
      if tournament.prize_strategy == :prize_pool,
        do: tournament.prize_pool,
        else: tournament.distribution_prize_pool

    rank in Map.keys(prize_pool)
  end

  attr(:id, :string, required: true)
  attr(:party_name, :string, required: true)
  attr(:party_member_id, :string, required: true)

  defp leave_team_modal(assigns) do
    ~H"""
    <.modal_small id={@id}>
      <:header>
        <div class="flex items-center justify-center gap-2">
          <img class="mb-2 rounded-b max-h-20" src="/images/font-awesome/alert.svg" alt="alert" />
          Leave <%= @party_name %> roster?
        </div>
      </:header>

      <p class="text-xs text-grey-light">
        Are you sure you want to leave your team? This cannot be undone, you will need to be invited back by the Team Manager or Captain to rejoin.
      </p>

      <:cancel>
        <.button
          id="cancel-button-leave-modal"
          class="rounded border-grey-light text-grey-light"
          phx-click={hide_modal(@id)}
        >
          Cancel
        </.button>
      </:cancel>

      <:confirm>
        <.button
          id={"drop-party-member-button-leave-modal-#{@party_member_id}"}
          button_type={:secondary}
          class="text-white rounded"
          phx-click="drop-party-member"
          phx-value-id={@party_member_id}
        >
          Leave Team
        </.button>
      </:confirm>
    </.modal_small>
    """
  end

  attr(:id, :string, required: true)
  attr(:tournament_name, :string, required: true)
  attr(:participant_id, :string, required: true)

  def drop_myself_from_tournament_modal(assigns) do
    ~H"""
    <.modal_small id={@id}>
      <:header>
        <div class="flex items-center justify-center gap-2">
          <img class="mb-2 rounded-b max-h-20" src="/images/font-awesome/alert.svg" alt="alert" />
          Drop from <%= @tournament_name %>?
        </div>
      </:header>

      <p class="text-xs text-grey-light">
        Are you sure you want to drop? You will immediately be removed from the tournament.
      </p>

      <:cancel>
        <.button
          id="cancel-button-leave-modal"
          class="rounded border-grey-light text-grey-light"
          phx-click={hide_modal(@id)}
        >
          Cancel
        </.button>
      </:cancel>

      <:confirm>
        <.button
          id={"drop-myself-from-tournament-button-#{@participant_id}"}
          button_type={:secondary}
          class="text-white rounded"
          phx-click="drop-and-refund"
          phx-value-participant={@participant_id}
        >
          Drop Team
        </.button>
      </:confirm>
    </.modal_small>
    """
  end
end
