defmodule StridentWeb.TournamentLive.DetailCardsGrid do
  @moduledoc """
  Tournament details as grid of cards with icons
  """
  use StridentWeb, :live_component
  alias Strident.Prizes
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.Tournaments

  attr(:tournament, :any, required: true)
  attr(:timezone, :any, required: true)
  attr(:locale, :any, required: true)
  attr(:orientation, :atom, default: :horizontal)

  def render(assigns) do
    assigns = assign_discord_link(assigns)

    ~H"""
    <div class={[
      "flex flex-col gap-4",
      if(@orientation == :horizontal, do: "md:justify-between md:flex-row")
    ]}>
      <div class="grid grid-cols-1 gap-4 grow md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <.custom_colored_card id="tournament-game-info">
          <div class="flex flex-col justify-center px-4 gap-y-4">
            <.custom_image
              id="tournament-game-logo"
              image_url={@tournament.game.cover_image_url}
              alt={@tournament.game.title}
              class="object-scale-down h-14"
            />
            <div>
              <p class="text-xs text-grey-light">Game</p>
              <p><%= @tournament.game.title %></p>
            </div>
          </div>
        </.custom_colored_card>

        <.custom_colored_card id="tournament-prize-pool-info">
          <div class="flex flex-col px-4 gap-y-4">
            <.custom_image
              id="tournament-prize-pool-png"
              image_url="https://strident-games.s3.amazonaws.com/icon_trophy.png"
              alt="Prize Pool"
              class="object-cover w-16 h-14"
            />
            <div>
              <p class="text-xs text-grey-light">Prize Pool</p>
              <%!-- ADDED AS HACK FOR OFF SYSTEM TOURNAMENT PRIZE DISTRIBUTION CAN BE REMOVED WHEN TOURNAMENT COMPLETED--%>
              <%= if @tournament.id in ["8b86e43d-d16b-4232-9c05-2e3671e05a67"] do %>
                <p><%= Money.new("USD", "10000") %></p>
              <% end %>
            </div>
          </div>
        </.custom_colored_card>

        <.custom_colored_card id="tournament-entry-fee-info">
          <div class="flex flex-col px-4 gap-y-4">
            <.custom_image
              id="tournament-entry-fee-png"
              image_url="https://strident-games.s3.amazonaws.com/icon_dollarSign.png"
              alt="Entry Fee"
              class="object-cover w-7 h-[54px]"
            />
            <div>
              <p class="text-xs text-grey-light">Entry Fee</p>
              <p><%= @tournament.buy_in_amount %></p>
            </div>
          </div>
        </.custom_colored_card>

        <.custom_colored_card id="tournament-start-time-info">
          <div class="flex flex-col px-4 gap-y-4">
            <.custom_image
              id="tournament-start-time-png"
              image_url="https://strident-games.s3.amazonaws.com/icon_calendar.png"
              alt="Start Time"
              class="object-cover w-12 h-14"
            />
            <div>
              <p class="text-xs text-grey-light">Tournament Starts</p>
              <.localised_datetime
                datetime={@tournament.starts_at}
                timezone={@timezone}
                locale={@locale}
                type={:datetime}
              />
            </div>
          </div>
        </.custom_colored_card>

        <.custom_colored_card id="tournament-format-info">
          <div class="flex flex-col px-4 gap-y-4">
            <.custom_image
              id="tournament-format-png"
              image_url="https://strident-games.s3.amazonaws.com/icon_singleElimination.png"
              alt="Tournament Format"
              class="object-cover w-[86px] h-14"
            />
            <div>
              <p class="text-xs text-grey-light">Format</p>
              <p><%= @tournament.stages |> Enum.map(&humanize(&1.type)) |> Enum.join(",") %></p>
            </div>
          </div>
        </.custom_colored_card>

        <.custom_colored_card id="tournament-platform-info">
          <div class="flex flex-col px-4 gap-y-4">
            <.custom_image
              id="tournament-platform-png"
              image_url="https://strident-games.s3.amazonaws.com/icon_controller.png"
              alt="Platform"
              class="object-cover w-[92px] h-[46px]"
            />
            <div>
              <p class="text-xs text-grey-light">Platform</p>
              <p><%= humanize(@tournament.platform) %></p>
            </div>
          </div>
        </.custom_colored_card>

        <.custom_colored_card id="tournament-registered-participants-info">
          <div class="flex flex-col px-4 gap-y-4">
            <.custom_image
              id="tournament-registered-participants-png"
              image_url="https://strident-games.s3.amazonaws.com/icon_users.png"
              alt="Number of participants"
              class="object-cover w-[67px] h-[54px]"
            />
            <div>
              <p class="text-xs text-grey-light">Registered Participants</p>
              <p>
                <%= Enum.count(
                  @tournament.participants,
                  &(&1.status in Tournaments.on_track_statuses())
                ) %> Participants
              </p>
            </div>
          </div>
        </.custom_colored_card>

        <.custom_colored_card id="tournament-players-per-team-info">
          <div class="flex flex-col px-4 gap-y-4">
            <.custom_image
              id="tournament-players-per-team-png"
              image_url="https://strident-games.s3.amazonaws.com/icon_user.png"
              alt="Players per Team"
              class="object-cover"
            />
            <div>
              <p class="text-xs text-grey-light">Players per Team</p>
              <p><%= @tournament.players_per_participant %> Players</p>
            </div>
          </div>
        </.custom_colored_card>
      </div>

      <.custom_colored_card_prize id="tournament-overview">
        <div class="flex flex-col justify-center gap-4 px-4 w-96">
          <div>
            <h4 class="mb-2 mr-4 uppercase font-bold">Prize Places</h4>
            <div
              :for={{rank, prize} <- @tournament.prize_pool}
              :if={@tournament.prize_strategy == :prize_pool and Enum.any?(@tournament.prize_pool)}
            >
              <%= Prizes.format_prize_rank(rank) %> - <%= prize %>
            </div>
            <div
              :for={{rank, procentage} <- @tournament.prize_distribution}
              :if={
                @tournament.prize_strategy == :prize_distribution and
                  Enum.any?(@tournament.prize_distribution)
              }
            >
              <%= Prizes.format_prize_rank(rank) %>
              <span class="text-grey-light">(<%= procentage %>%)</span>
            </div>

            <p
              :if={
                Enum.empty?(@tournament.prize_distribution) and Enum.empty?(@tournament.prize_pool)
              }
              class="italic text-grey-light"
            >
              No prize pool
            </p>
          </div>

          <div>
            <h4 class="mb-2 mr-4 uppercase font-bold">Tournament Organizer</h4>

            <div :if={is_nil(@tournament.created_by.slug)} class="flex items-center space-x-2">
              Anonymous
            </div>

            <div :if={@tournament.created_by.slug} class="flex items-center space-x-2">
              <.image
                id={"created-by-avatar-#{@tournament.created_by.id}"}
                image_url={Strident.Accounts.avatar_url(@tournament.created_by)}
                alt="logo"
                class="rounded-full"
                width={48}
                height={48}
              />
              <.link navigate={~p"/user/#{@tournament.created_by.slug}"} class="text-primary">
                <%= @tournament.created_by.display_name %>
              </.link>
            </div>
          </div>

          <.link
            :if={@discord_link}
            href={@discord_link.user_input}
            class="flex items-center"
            target="_blank"
            rel="noopener noreferrer"
          >
            <.svg icon={:discord} width="24" height="24" class="mr-2 fill-brands-discord" />
            <p class="uppercase text-brands-discord">Join Tournament Discord</p>
          </.link>
        </div>
      </.custom_colored_card_prize>
    </div>
    """
  end

  def assign_discord_link(assigns) do
    %{tournament: tournament} = assigns

    tournament.social_media_links
    |> Enum.filter(&(&1.brand == :discord))
    |> Enum.at(0)
    |> then(fn
      nil -> nil
      link -> SocialMediaLink.add_user_input(link)
    end)
    |> then(&assign(assigns, :discord_link, &1))
  end

  attr(:id, :string, required: true)
  slot(:inner_block, required: true)

  defp custom_colored_card(assigns) do
    ~H"""
    <.colored_card id={@id} class="" inner_class="flex justify-start h-full py-4 lg:py-6">
      <%= render_slot(@inner_block) %>
    </.colored_card>
    """
  end

  defp custom_colored_card_prize(assigns) do
    ~H"""
    <.colored_card id={@id} class="h-fit" inner_class="flex justify-start h-fit py-4 lg:py-6">
      <%= render_slot(@inner_block) %>
    </.colored_card>
    """
  end

  attr(:id, :string, required: true)
  attr(:image_url, :string, required: true)
  attr(:alt, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:height, :integer, default: 56)
  attr(:width, :integer, default: 56)

  defp custom_image(assigns) do
    ~H"""
    <.image
      id={@id}
      image_url={@image_url}
      alt={@alt}
      class={@class}
      width={@width}
      height={@height}
      resize={:fit}
    />
    """
  end
end
