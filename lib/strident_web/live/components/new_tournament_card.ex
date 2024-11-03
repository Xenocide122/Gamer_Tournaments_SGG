defmodule StridentWeb.Components.NewTournamentCard do
  @moduledoc """
  New Tournament card
  """
  use StridentWeb, :live_component

  alias Strident.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"overflow-hidden rounded bg-blackish #{@class}"}>
      <.link
        navigate={
          tournaments_link_based_on_creator(
            @tournament.created_by_user_id,
            @current_user_id,
            @tournament.slug
          )
        }
        class="flex flex-col h-full"
      >
        <div class="relative">
          <.image
            id={"new-tournament-card-bg-image-#{@tournament.id}"}
            image_url={@tournament.thumbnail_image_url || @tournament.game.default_game_banner_url}
            alt={@tournament.title}
            class="object-cover w-full text-center font-display"
            width={256}
            height={256}
            resize={:fit}
          />

          <%= status_label(@tournament) %>
        </div>

        <div class="flex flex-col flex-1 p-6">
          <div class="flex-1 mb-6 text-center">
            <div class="mb-1 text-3xl font-display h-[72px] flex items-center justify-center">
              <span class="line-clamp-2">
                <%= @tournament.title %>
              </span>
            </div>

            <.localised_datetime
              datetime={@tournament.starts_at}
              timezone={@timezone}
              locale={@locale}
              class="text-sm text-grey-light"
            />
          </div>

          <ul class="mb-8 space-y-3">
            <li class="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                fill="currentColor"
                class="mr-3 text-primary"
              >
                <path d="M22 8.65A5 5 0 0 0 17 4H7a5 5 0 0 0-5 4.74A2 2 0 0 0 2 9v7.5A3.48 3.48 0 0 0 5.5 20c1.43 0 2.32-1.06 3.19-2.09.32-.37.65-.76 1-1.1a4.81 4.81 0 0 1 1.54-.75 6.61 6.61 0 0 1 1.54 0 4.81 4.81 0 0 1 1.54.75c.35.34.68.73 1 1.1.87 1 1.76 2.09 3.19 2.09a3.48 3.48 0 0 0 3.5-3.5V9a2.09 2.09 0 0 0 0-.26zm-2 7.85a1.5 1.5 0 0 1-1.5 1.5c-.5 0-1-.64-1.66-1.38-.34-.39-.72-.85-1.15-1.26a6.68 6.68 0 0 0-2.46-1.25 6.93 6.93 0 0 0-2.46 0 6.68 6.68 0 0 0-2.46 1.25c-.43.41-.81.87-1.15 1.26C6.54 17.36 6 18 5.5 18A1.5 1.5 0 0 1 4 16.5V9a.77.77 0 0 0 0-.15A3 3 0 0 1 7 6h10a3 3 0 0 1 3 2.72v.12A.86.86 0 0 0 20 9z">
                </path>
                <circle cx="16" cy="12" r="1"></circle>
                <circle cx="18" cy="10" r="1"></circle>
                <circle cx="16" cy="8" r="1"></circle>
                <circle cx="14" cy="10" r="1"></circle>
                <circle cx="8" cy="10" r="2"></circle>
              </svg>
              <div class="flex-1 truncate">
                <%= @tournament.game.title %>
              </div>
            </li>

            <li class="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                fill="currentColor"
                class="mr-3 text-primary"
              >
                <path d="M21 4H3a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h18a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1zm-1 11a3 3 0 0 0-3 3H7a3 3 0 0 0-3-3V9a3 3 0 0 0 3-3h10a3 3 0 0 0 3 3v6z">
                </path>
                <path d="M12 8c-2.206 0-4 1.794-4 4s1.794 4 4 4 4-1.794 4-4-1.794-4-4-4zm0 6c-1.103 0-2-.897-2-2s.897-2 2-2 2 .897 2 2-.897 2-2 2z">
                </path>
              </svg>
              <div class="flex-1 truncate">
                <%= @tournament.buy_in_amount %> Entry Fee
              </div>
            </li>

            <li class="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                fill="currentColor"
                class="mr-3 text-primary"
              >
                <path d="M21 4h-3V3a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1v1H3a1 1 0 0 0-1 1v3c0 4.31 1.799 6.91 4.819 7.012A6.001 6.001 0 0 0 11 17.91V20H9v2h6v-2h-2v-2.09a6.01 6.01 0 0 0 4.181-2.898C20.201 14.91 22 12.31 22 8V5a1 1 0 0 0-1-1zM4 8V6h2v6.83C4.216 12.078 4 9.299 4 8zm8 8c-2.206 0-4-1.794-4-4V4h8v8c0 2.206-1.794 4-4 4zm6-3.17V6h2v2c0 1.299-.216 4.078-2 4.83z">
                </path>
              </svg>
            </li>

            <li class="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                fill="currentColor"
                class="mr-3 text-primary"
              >
                <path d="M16.604 11.048a5.67 5.67 0 0 0 .751-3.44c-.179-1.784-1.175-3.361-2.803-4.44l-1.105 1.666c1.119.742 1.8 1.799 1.918 2.974a3.693 3.693 0 0 1-1.072 2.986l-1.192 1.192 1.618.475C18.951 13.701 19 17.957 19 18h2c0-1.789-.956-5.285-4.396-6.952z">
                </path>
                <path d="M9.5 12c2.206 0 4-1.794 4-4s-1.794-4-4-4-4 1.794-4 4 1.794 4 4 4zm0-6c1.103 0 2 .897 2 2s-.897 2-2 2-2-.897-2-2 .897-2 2-2zm1.5 7H8c-3.309 0-6 2.691-6 6v1h2v-1c0-2.206 1.794-4 4-4h3c2.206 0 4 1.794 4 4v1h2v-1c0-3.309-2.691-6-6-6z">
                </path>
              </svg>
              <div class="flex-1 truncate">
                <%= if(is_nil(@tournament.required_participant_count),
                  do: "Unlimited",
                  else:
                    "#{number_of_confirmed_participants(@tournament)} / #{@tournament.required_participant_count}"
                ) %> Participants
              </div>
            </li>
          </ul>

          <button class="w-full font-semibold btn btn--primary">
            See details
          </button>
        </div>
      </.link>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(tournament: assigns.tournament)
    |> assign_current_user_id(assigns)
    |> assign_maybe_class(assigns)
    |> then(&{:ok, &1})
  end

  defp number_of_confirmed_participants(tournament) do
    Tournaments.get_number_of_confirmed_participants(tournament)
  end

  defp status_label(%{status: :scheduled} = assigns) do
    ~H"""
    <%= build_status(%{status: "Registration open soon"}) %>
    """
  end

  defp status_label(%{status: :registrations_open, type: :casting_call} = assigns) do
    ~H"""
    <%= build_status(%{status: "Registration Open"}) %>
    """
  end

  defp status_label(%{status: :registrations_open, type: :invite_only} = assigns) do
    ~H"""

    """
  end

  defp status_label(%{status: :registrations_closed} = assigns) do
    ~H"""
    <%= build_status(%{status: "Coming soon"}) %>
    """
  end

  defp status_label(%{status: :in_progress} = assigns) do
    ~H"""
    <%= build_status(%{status: "Live tournament"}) %>
    """
  end

  defp status_label(%{status: status} = assigns) when status in [:under_review, :finished] do
    ~H"""
    <%= build_status(%{status: "Completed"}) %>
    """
  end

  defp status_label(%{status: :cancelled} = assigns) do
    ~H"""
    <div class="absolute bottom-0 left-0 flex items-stretch">
      <div class="relative px-3 py-2 text-sm font-semibold uppercase bg-secondary">
        Canceled
      </div>
    </div>
    """
  end

  defp build_status(assigns) do
    ~H"""
    <div class="absolute bottom-0 left-0 flex items-stretch">
      <div class="relative px-3 py-2 text-sm font-semibold uppercase bg-gradient-to-r from-grilla-blue to-grilla-pink">
        <%= @status %>
      </div>
    </div>
    """
  end

  defp assign_maybe_class(socket, %{class: class}) do
    assign(socket, class: class)
  end

  defp assign_maybe_class(socket, _assigns) do
    assign(socket, class: nil)
  end

  defp assign_current_user_id(socket, %{current_user: nil}) do
    assign(socket, current_user_id: nil)
  end

  defp assign_current_user_id(socket, %{current_user: current_user}) do
    assign(socket, current_user_id: current_user.id)
  end

  defp assign_current_user_id(socket, _assigns) do
    assign(socket, current_user_id: nil)
  end

  defp tournaments_link_based_on_creator(tournament_creator_id, current_user_id, tournament_slug) do
    if tournament_creator_id == current_user_id do
      Routes.live_path(StridentWeb.Endpoint, StridentWeb.TournamentDashboardLive, tournament_slug)
    else
      Routes.tournament_show_pretty_path(StridentWeb.Endpoint, :show, tournament_slug)
    end
  end
end
