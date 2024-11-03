defmodule StridentWeb.TournamentDashboardLive.Components.ParticipantCard do
  @moduledoc false
  use StridentWeb, :live_component

  alias Strident.Accounts
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Strident.Tournaments.TournamentInvitation
  alias StridentWeb.Endpoint
  alias StridentWeb.Router.Helpers, as: Routes

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-96">
      <.card colored={true}>
        <.link
          navigate={@profile_link}
          class="flex flex-col justify-center overflow-hidden lg:flex-row lg:justify-start"
        >
          <img
            src={TournamentParticipants.participant_logo_url(@participant)}
            class="self-center w-12 h-12 mx-2 my-4 rounded-full"
            alt="player"
          />
          <div class="flex-1 min-w-0 mt-4">
            <%= get_participant_name(@participant) %>
            <%= build_status(@participant) %>
            <%= if @participant.active_invitation do %>
              <%= build_last_notification(@participant) %>
            <% end %>
          </div>
        </.link>
      </.card>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{participant: participant, tournament: tournament} = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:participant, participant)
    |> assign(:tournament, tournament)
    |> assign(:show_confirmation, nil)
    |> assign_profile_link()
    |> then(&{:ok, &1})
  end

  def get_participant_name(%{active_invitation: %{status: :pending}} = assigns) do
    ~H"""
    <p class="text-sm text-center truncate lg:text-left text-grey-light">
      <%= TournamentParticipants.participant_name(assigns, show_email: true) %>
    </p>
    """
  end

  def get_participant_name(%{status: :empty} = assigns) do
    ~H"""
    <p class="text-center truncate lg:text-left text-grey-light">
      <%= TournamentParticipants.participant_name(assigns) %>
    </p>
    """
  end

  def get_participant_name(assigns) do
    ~H"""
    <p class="text-center truncate lg:text-left text-primary">
      <%= TournamentParticipants.participant_name(assigns) %>
    </p>
    """
  end

  def build_status(%{checked_in: true, status: :confirmed} = assigns) do
    ~H"""
    <div class="flex items-center mb-3">
      <p class="mr-1 text-sm truncate lg:text-left text-grey-light">
        Checked In
      </p>
      <.svg icon={:circle_check} width="20" height="20" class="fill-primary" />
    </div>
    """
  end

  def build_status(%{status: :confirmed} = assigns) do
    ~H"""
    <p class="mb-3 text-sm text-center truncate lg:text-left text-grey-light">
      Confirmed participant
    </p>
    """
  end

  def build_status(
        %{active_invitation: %{status: :accepted}, stake: %{staking_successful: true}} = assigns
      ) do
    ~H"""
    <p class="mb-3 text-sm text-center truncate lg:text-left text-grey-light">
      Entry fee Paid
    </p>
    """
  end

  def build_status(%{active_invitation: %{status: :accepted}} = assigns) do
    ~H"""
    <p class="mb-3 text-sm text-center truncate lg:text-left text-grey-light">
      Registered | <span class="text-secondary">Unpaid Entry</span>
    </p>
    """
  end

  def build_status(%{status: :empty} = assigns) do
    ~H"""

    """
  end

  def build_status(assigns) do
    ~H"""
    <p class="mb-2 text-sm text-center truncate lg:text-left text-secondary">
      Unregistered
    </p>
    """
  end

  def build_last_notification(
        %{active_invitation: %{status: :accepted}, stake: %{staking_successful: true}} = assigns
      ) do
    ~H"""

    """
  end

  @doc """
  Gets time and date for last email notification
  """
  def build_last_notification(%{active_invitation: %TournamentInvitation{}} = assigns) do
    ~H"""
    <p class="mb-4 text-xs text-center lg:truncate lg:text-left text-grey-light">
      Last reminder sent <%= @active_invitation.inserted_at
      |> NaiveDateTime.to_date()
      |> Date.to_string() %>
    </p>
    """
  end

  defp assign_profile_link(socket) do
    %{assigns: %{participant: participant, tournament: tournament}} = socket
    participant = Strident.Repo.preload(participant, [:team, :party, players: [:user]])

    default_path =
      Routes.live_path(Endpoint, StridentWeb.TournamentDashboardLive, tournament.slug)

    profile_link =
      case Tournaments.get_tournament_participant_type(
             participant,
             tournament.players_per_participant
           ) do
        :team ->
          Routes.live_path(Endpoint, StridentWeb.TeamProfileLive.Show, participant.team.slug)

        :party when tournament.participant_type == :individual ->
          case participant.players do
            [%{user: user} | _] -> Routes.user_show_path(Endpoint, :show, user.slug)
            _ -> default_path
          end

        :party ->
          Routes.live_path(
            Endpoint,
            StridentWeb.PartyManagementLive.Index,
            participant.party.id,
            %{
              "tournament" => tournament.id
            }
          )

        :user ->
          case participant.players do
            [%{user: %{slug: user_slug}}] when is_binary(user_slug) ->
              Routes.user_show_path(Endpoint, :show, user_slug)

            _ ->
              default_path
          end

        :unknown ->
          default_path
      end

    assign(socket, :profile_link, profile_link)
  end
end
