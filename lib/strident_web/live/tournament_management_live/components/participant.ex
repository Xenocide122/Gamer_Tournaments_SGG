defmodule StridentWeb.TournamentManagement.Components.Participant do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Repo
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias StridentWeb.Endpoint
  alias StridentWeb.Router.Helpers, as: Routes
  alias StridentWeb.TournamentParticipants.TournamentParticipantsHelpers

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{
      can_manage_tournament: can_manage_tournament,
      tournament: tournament,
      participant: participant,
      stake: stake,
      ranks_frequency: ranks_frequency
    } = assigns

    participant = Repo.preload(participant, active_invitation: [], party: [], team: [])

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:can_manage_tournament, can_manage_tournament)
    |> assign(:tournament, tournament)
    |> assign(:stake, stake)
    |> assign(:ranks_frequency, ranks_frequency)
    |> assign(%{
      participant_id: participant.id,
      participant_status: participant.status
    })
    |> assign_participant_name(participant)
    |> assign_participant_avatar(participant)
    |> assign_participant_slug(participant)
    |> assign_label_text_and_status(participant)
    |> assign_profile_link(participant)
    |> assign_go_stake_me_link(participant)
    |> assign_view_link(participant)
    |> assign_progress_bar(participant)
    |> then(&{:ok, &1})
  end

  attr(:tournament_allow_staking, :boolean, required: true)
  attr(:tournament_status, :atom, required: true)
  attr(:participant_status, :atom, required: true)
  attr(:participant_id, :string, required: true)
  attr(:progress_bar, :any, required: true)

  defp display_participant_body(assigns) do
    progress_bar_color =
      case assigns.participant_status do
        :confirmed -> "gradient"
        :chip_in_to_entry_fee -> "bg-grilla-pink"
        :contribution_to_entry_fee -> "bg-primary"
        _ -> nil
      end

    assigns = assign(assigns, :progress_bar_color, progress_bar_color)

    ~H"""
    <div class="display-participant-body">
      <.display_progress
        :if={
          @tournament_allow_staking and @tournament_status in [:scheduled, :registrations_open] and
            !!@progress_bar_color
        }
        progress_bar={@progress_bar}
        color={@progress_bar_color}
        participant_id={@participant_id}
      />
    </div>
    """
  end

  defp display_progress(assigns) do
    circumference = 20 * 2 * :math.pi()
    assigns = Map.put(assigns, :circumference, circumference)

    ~H"""
    <div>
      <div class="hidden px-4 mt-4 md:block md:row-span-1">
        <.progress_bar
          id={"participant-bar-#{@participant_id}"}
          procentage={@progress_bar}
          color={@color}
        />
        <p class="text-right md:text-left md:text-xs text-primary">
          <%= @progress_bar %>% of Entry Fee Covered
        </p>
      </div>

      <div class="inline-flex items-center justify-center overflow-hidden rounded-full md:hidden">
        <svg class="w-16 h-16">
          <circle class="fill-transparent stroke-grey-light" stroke-width="5" r="20" cx="30" cy="30" />
          <circle
            stroke-dasharray={@circumference}
            stroke-dashoffset={@circumference - @progress_bar / 100 * @circumference}
            stroke-width="5"
            class="fill-transparent stroke-primary"
            r="20"
            cx="30"
            cy="30"
          />
        </svg>
        <span class="absolute text-xs text-primary" x-text={"`#{@progress_bar}%`"}></span>
      </div>
    </div>
    """
  end

  def assign_label_text_and_status(socket, participant) do
    %{tournament: tournament, ranks_frequency: ranks_frequency} = socket.assigns

    active_invitation_status =
      case participant do
        %{active_invitation: %{status: status}} -> status
        _ -> nil
      end

    label_text =
      TournamentParticipants.status_label(
        participant.status,
        participant.rank,
        tournament.status,
        active_invitation_status,
        ranks_frequency
      )

    label_class =
      case label_text do
        "Crowdfunding Entry Fee" -> "text-sm text-primary"
        "Participant Invited" -> "text-sm text-left text-grey-light"
        "" -> ""
        "Participant Entered" -> "text-sm text-grey-light"
        "Playing Now" -> "text-sm text-grey-light"
        "1st" -> "text-xl font-bold text-left font-display first-place-rank__gradient"
        "2nd" -> "text-xl font-bold text-left font-display text-primary"
        "3rd" -> "text-xl font-bold text-left font-display text-primary"
        "TOP " <> _ -> "text-xl font-bold text-left font-display text-primary"
        "Unranked" -> "text-xl font-bold text-left uppercase font-display text-grey-light"
        _ -> "text-xl font-bold text-left font-display text-grey-light"
      end

    socket
    |> assign(:label_text, label_text)
    |> assign(:label_class, label_class)
  end

  def assign_progress_bar(socket, participant) do
    %{tournament: tournament} = socket.assigns

    tournament.buy_in_amount
    |> TournamentParticipants.entry_fee_progression(participant)
    |> then(&assign(socket, :progress_bar, &1))
  end

  defp assign_participant_name(socket, participant) do
    %{can_manage_tournament: can_manage_tournament} = socket.assigns

    assign(
      socket,
      :participant_name,
      TournamentParticipants.participant_name(participant, show_email: can_manage_tournament)
    )
  end

  defp assign_participant_slug(socket, participant) do
    %{tournament: tournament} = socket.assigns

    assign(
      socket,
      :participant_slug,
      Tournaments.get_slug_for_go_stake_me(participant, tournament.players_per_participant)
    )
  end

  defp assign_go_stake_me_link(socket, participant) do
    %{tournament: tournament} = socket.assigns

    participant_slug =
      Tournaments.get_slug_for_go_stake_me(participant, tournament.players_per_participant)

    go_stake_me_link =
      if participant_slug == nil do
        Routes.tournament_show_pretty_path(Endpoint, :show, tournament.slug)
      else
        Routes.live_path(
          Endpoint,
          StridentWeb.GoStakeMeLive,
          socket.assigns.tournament.slug,
          participant_slug
        )
      end

    assign(socket, :go_stake_me_link, go_stake_me_link)
  end

  defp assign_profile_link(socket, participant) do
    %{tournament: tournament} = socket.assigns
    profile_link = TournamentParticipantsHelpers.profile_link(participant, tournament)
    assign(socket, :profile_link, profile_link)
  end

  defp assign_view_link(socket, participant) do
    %{tournament: tournament, go_stake_me_link: go_stake_me_link, profile_link: profile_link} =
      socket.assigns

    view_link =
      if (tournament.allow_staking and participant.status == :confirmed) or
           participant.status == :confirmed do
        profile_link
      else
        go_stake_me_link
      end

    assign(socket, :view_link, view_link)
  end

  defp assign_participant_avatar(socket, participant) do
    assign(socket, :participant_avatar, TournamentParticipants.participant_logo_url(participant))
  end
end
