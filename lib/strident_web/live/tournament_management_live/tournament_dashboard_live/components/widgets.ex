# defmodule StridentWeb.TournamentDashboardLive.Components.TotalEntryFeesCollected do÷
defmodule StridentWeb.TournamentDashboardLive.Components.Widgets do
  @moduledoc false
  # use StridentWeb, :live_component

  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: StridentWeb.Endpoint, router: StridentWeb.Router

  import StridentWeb.Common.SvgUtils
  import StridentWeb.Components.Containers
  import StridentWeb.Components.LocalisedDate
  import StridentWeb.DeadViews.Button, only: [button: 1]

  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias StridentWeb.Components.ProgressBar
  alias StridentWeb.DeadViews.Button
  alias StridentWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.JS

  def cancelled(assigns) do
    ~H"""
    <div class="rounded bg-secondary p-[1px]">
      <div class="rounded bg-blackish py-[8px] lg:px-3">
        <div class="flex items-center justify-center my-8">
          <svg
            width="40"
            height="40"
            viewBox="0 0 24 24"
            class="mr-2 stroke-secondary fill-none"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d={StridentWeb.Common.SvgUtils.path(:exclamation)}
            />
          </svg>
          <h3 class="uppercase text-secondary">
            Tournament Canceled
          </h3>
        </div>

        <div class="mb-8 text-center text-grey-light">
          This tournament was canceled and all participants and fan contributors were refunded on
          <.localised_datetime
            datetime={@tournament.updated_at}
            timezone={@timezone}
            locale={@locale}
            type={:date}
          /> at
          <.localised_datetime
            datetime={@tournament.updated_at}
            timezone={@timezone}
            locale={@locale}
            type={:time}
          />
        </div>
      </div>
    </div>
    """
  end

  def participant(assigns) do
    ~H"""
    <div>
      <.link
        navigate={assign_profile_link(@participant, @tournament)}
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
        </div>
      </.link>
    </div>
    """
  end

  attr(:class, :any, default: nil)
  attr(:tournament_prize_strategy, :any)
  attr(:progress_bar, :any)
  attr(:tournament_slug, :string)
  attr(:tournament_id, :string)

  slot(:title)
  slot(:amt, required: true)

  def prize_pool(assigns) do
    ~H"""
    <%!-- <div class="rounded-lg bg-primary shadow-md shadow-primary p-[1px] mb-8 lg:mb-0 basis-0 grow lg:h-48"> --%>
    <div class="flex-auto w-full lg:w-1/3 h-auto">
      <.wide_card colored={true}>
        <div class="h-48 max-h-full rounded-lg bg-blackish mb-4">
          <div class="flex items-center">
            <img
              width="50"
              height="50"
              class="mr-1 rounded-b max-h-20"
              src="/images/font-awesome/money-bill-wave.svg"
              alt="users"
            />
            <h4 class="uppercase text-primary"><%= render_slot(@title) %></h4>
          </div>

          <div class="flex justify-center py-6">
            <h2>
              <%= render_slot(@amt) %>
            </h2>
          </div>

          <div :if={@tournament_prize_strategy == :prize_pool}>
            <hr class="border-t-2 border-grey-medium" />

            <div class="px-2 py-2 text-xs">
              <p>Entry Fees Paid of Prize Pool</p>

              <ProgressBar.progress_bar
                id="tournament-progress-bar"
                procentage={@progress_bar}
                height="2"
              />
            </div>
          </div>

          <div :if={@tournament_prize_strategy == :prize_distribution} class="flex justify-center">
            <Button.button
              id={"tournament-contribution-button-#{@tournament_id}"}
              button_type={:primary}
              phx-click={JS.navigate("/t/#{@tournament_slug}/contribution")}
            >
              Contribute To Prize Pool
            </Button.button>
          </div>
        </div>
      </.wide_card>
    </div>
    """
  end

  attr(:tournament, :any, required: true)
  attr(:number_of_confirmed_participants, :any, required: true)
  attr(:number_of_participants_still_raising_stakes, :any, required: true)
  attr(:timezone, :string)
  attr(:locale, :string)

  def sign_ups(assigns) do
    ~H"""
    <div class="flex-auto w-full lg:w-1/3 h-auto">
      <.wide_card colored={true}>
        <%!-- <div class="rounded-lg bg-primary shadow-md shadow-primary p-[1px] mb-8 lg:mb-0 basis-0 grow lg:h-48"> --%>
        <div class="h-48 max-h-full rounded-lg bg-blackish mb-4">
          <div class="flex items-center">
            <img
              width="50"
              height="50"
              class="mr-1 rounded-b max-h-20"
              src="/images/font-awesome/users.svg"
              alt="users"
            />
            <h4 class="uppercase text-primary">Sign Ups</h4>
          </div>

          <div class="flex justify-center py-6">
            <h2 :if={!!@tournament.required_participant_count}>
              <%= @number_of_confirmed_participants %> / <%= @tournament.required_participant_count %>
            </h2>
            <h2 :if={!@tournament.required_participant_count}>
              <%= @number_of_confirmed_participants %>
            </h2>
          </div>

          <%= if @tournament.allow_staking do %>
            <hr class="border-t-2 border-grey-medium" />

            <div class="flex justify-center p-4 text-sm">
              <%= if @number_of_participants_still_raising_stakes == 0 do %>
                No potential participants are raising entry fees
              <% else %>
                <%= @number_of_participants_still_raising_stakes %> potential participants are raising entry fees
              <% end %>
            </div>
          <% end %>

          <%= if @tournament.type == :casting_call and @tournament.status == :scheduled do %>
            <p class="text-sm text-center text-grey-light">
              Registration opens at
              <.localised_datetime
                datetime={@tournament.registrations_open_at}
                timezone={@timezone}
                locale={@locale}
              />
            </p>
          <% end %>

          <%= if @tournament.type == :casting_call and @tournament.status == :registrations_open do %>
            <p class="text-sm text-center text-grey-light">
              Registration close at
              <.localised_datetime
                datetime={@tournament.registrations_close_at}
                timezone={@timezone}
                locale={@locale}
              />
            </p>
          <% end %>
        </div>
      </.wide_card>
    </div>
    """
  end

  attr(:tournament_id, :string, required: true)

  def make_featured(assigns) do
    ~H"""
    <.button
      id={"add-to-featured-button-#{@tournament_id}"}
      button_type={:primary_default}
      phx-click="add-tournament-to-featured"
    >
      Add to Featured Tournaments
    </.button>
    """
  end

  attr(:tournament_id, :string, required: true)

  def remove_from_featured(assigns) do
    ~H"""
    <.button
      id={"remove-from-featured-button-#{@tournament_id}"}
      button_type={:secondary}
      phx-click="remove-tournament-from-featured"
    >
      Remove from Featured Tournaments
    </.button>
    """
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

  defp assign_profile_link(participant, tournament) do
    default_path =
      Routes.live_path(StridentWeb.Endpoint, StridentWeb.TournamentDashboardLive, tournament.slug)

    case Tournaments.get_tournament_participant_type(
           participant,
           tournament.players_per_participant
         ) do
      :team ->
        Routes.live_path(
          StridentWeb.Endpoint,
          StridentWeb.TeamProfileLive.Show,
          participant.team.slug
        )

      :party when tournament.participant_type == :individual ->
        case participant.players do
          [%{user: user} | _] -> Routes.user_show_path(StridentWeb.Endpoint, :show, user.slug)
          _ -> default_path
        end

      :party ->
        Routes.live_path(
          StridentWeb.Endpoint,
          StridentWeb.PartyManagementLive.Index,
          participant.party.id,
          %{
            "tournament" => tournament.id
          }
        )

      :user ->
        case participant.players do
          [%{user: %{slug: user_slug}}] when is_binary(user_slug) ->
            Routes.user_show_path(StridentWeb.Endpoint, :show, user_slug)

          _ ->
            default_path
        end

      :unknown ->
        default_path
    end
  end
end
