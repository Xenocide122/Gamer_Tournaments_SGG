defmodule StridentWeb.TournamentManagement.Components.TournamentOverview do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <div class="rounded gradient p-[1px]">
      <div class="rounded bg-blackish py-[8px] lg:px-3">
        <div class="relative flex flex-col items-center justify-center flex-1 min-w-0 lg:flex-row">
          <div
            :if={@tournament.is_scrim}
            class="flex items-center overflow-hidden lg:px-4 min-w-max text-grilla-blue"
          >
            <.svg icon={:tasks} width="20" height="20" class="mr-2 fill-current" />[Scrim]
          </div>

          <div class={[
            "flex items-center overflow-hidden min-w-max",
            if(@tournament.is_scrim, do: "lg:pr-4", else: "lg:px-4")
          ]}>
            <img
              width="50"
              height="50"
              class="mr-1 rounded-b max-h-20"
              src="/images/font-awesome/gamepad.svg"
              alt="gamepad"
            />
            <%= @tournament.game.title %>
          </div>

          <div class="flex items-center overflow-hidden lg:pr-4 min-w-max">
            <img
              width="50"
              height="50"
              class="mr-1 rounded-b max-h-20"
              src="/images/font-awesome/users.svg"
              alt="users"
            />
            <p :if={@short and is_nil(@tournament.required_participant_count)}>&infin;</p>
            <p :if={@short and !!@tournament.required_participant_count}>
              <%= number_of_confirmed_participants(@tournament) %>
            </p>
            <p :if={not @short and is_nil(@tournament.required_participant_count)}>
              <%= number_of_confirmed_participants(@tournament) %> Participants
            </p>
            <p :if={not @short and !!@tournament.required_participant_count}>
              <%= "#{number_of_confirmed_participants(@tournament)} / #{@tournament.required_participant_count}" %> Participants
            </p>
          </div>

          <div class="flex items-center lg:pr-4 overflow-hidden min-w-max">
            <img
              width="50"
              height="50"
              class="mr-1 rounded-b max-h-20"
              src="/images/font-awesome/money-bill-alt.svg"
              alt="money"
            />

            <%= @tournament.buy_in_amount %> <span :if={not @short}> per participant</span>
          </div>

          <div class="flex items-center overflow-hidden lg:pr-4 min-w-max">
            <img
              width="30"
              height="30"
              class="mx-3 rounded-b lg:mr-1 max-h-20"
              src="/images/font-awesome/calendar-alt.svg"
              alt="calendar"
            />

            <p :if={@tournament.status == :cancelled} class="uppercase text-secondary">Cancelled</p>

            <.localised_datetime
              :if={@tournament.status != :cancelled}
              datetime={@tournament.starts_at}
              timezone={@timezone}
              locale={@locale}
              type={if(@short, do: :date, else: :datetime)}
            />
          </div>

          <div
            class={[
              "flex items-center overflow-hidden justify-between",
              if(not @has_prize_pool and not @has_prize_distribution, do: "hidden")
            ]}
            x-data="prizePoolDisplay"
            @resize.window.debounce="resize();"
          >
            <div x-bind="trophy" class="flex-none">
              <img
                width="40"
                height="40"
                src="/images/font-awesome/trophy.svg"
                alt="trophy"
                class="mx-2 lg:mr-1 max-h-20 min-w-fit"
              />
            </div>

            <.live_component
              timezone={@timezone}
              locale={@locale}
              id={"tournament-live-prize-pool-#{@tournament.id}"}
              module={
                case @tournament.prize_strategy do
                  :prize_pool -> StridentWeb.Components.PrizePool
                  :prize_distribution -> StridentWeb.Components.PrizeDistribution
                end
              }
              prize_strategy={@tournament.prize_strategy}
              prize_pool={@tournament.prize_pool}
              prize_distribution={@tournament.prize_distribution}
              class="min-w-max"
            />
            <div class="flex-none min-w-max" x-bind="seeMore">
              <div class="mx-4 link min-w-max" x-bind="seeMoreText">
                See More
              </div>
              <div
                class="absolute right-0 z-40 flex flex-col mt-2 mr-4 border border-black card--wide"
                x-bind="seeMoreDropdown"
                x-cloak
              >
                <span class="mb-1 text-muted">Prize Pool</span>
                <.live_component
                  timezone={@timezone}
                  locale={@locale}
                  id={"tournament-live-prize-pool-#{@tournament.id}-dropdown"}
                  module={
                    case @tournament.prize_strategy do
                      :prize_pool -> StridentWeb.Components.PrizePool
                      :prize_distribution -> StridentWeb.Components.PrizeDistribution
                    end
                  }
                  prize_strategy={@tournament.prize_strategy}
                  prize_pool={@tournament.prize_pool}
                  prize_distribution={@tournament.prize_distribution}
                  class="min-w-max"
                  position={:vertical_min}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{tournament: tournament} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:tournament, tournament)
    |> assign(
      :has_prize_pool,
      tournament.prize_strategy == :prize_pool and Enum.any?(tournament.prize_pool)
    )
    |> assign(
      :has_prize_distribution,
      tournament.prize_strategy == :prize_distribution and
        Enum.any?(tournament.prize_distribution)
    )
    |> assign(:is_free_tournament, Tournaments.is_free_buy_in_tournament?(tournament))
    |> assign(:short, Map.get(assigns, :short, false))
    |> then(&{:ok, &1})
  end

  defp number_of_confirmed_participants(tournament) do
    Tournaments.get_number_of_confirmed_participants(tournament)
  end
end
