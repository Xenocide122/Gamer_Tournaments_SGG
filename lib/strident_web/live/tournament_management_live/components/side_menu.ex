defmodule StridentWeb.TournamentManagement.Components.SideMenu do
  @moduledoc false
  use StridentWeb, :live_component

  alias Strident.Repo
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.Tournaments
  alias StridentWeb.TournamentPageLive

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="tournament-management-side-menu"
      class="sticky z-40 overflow-auto top-16 md:top-24 bg-strident-black/80"
    >
      <ul class="flex items-center gap-2 py-4 md:py-1 md:justify-center">
        <.menu_item
          :for={{item, index} <- Enum.with_index(@items)}
          index={index}
          url={item.url}
          title={item.title}
          mobile_title={item.mobile_title}
          push_patch={item.push_patch}
          selected={item.selected}
          number_of_updates={Map.get(item, :number_of_updates, 0)}
        />
      </ul>
    </div>
    """
  end

  @impl true
  def update(%{new_event: "invite-rejected"} = assigns, socket) do
    %{
      tournament: tournament,
      current_user: current_user
    } = assigns

    socket
    |> assign_roster_invites_page_item(tournament, current_user)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{current_user: nil} = assigns, socket) do
    %{
      tournament: tournament,
      live_action: live_action,
      number_of_participants: number_of_participants
    } = assigns

    socket
    |> assign(:live_action, live_action)
    |> assign(:tournament_slug, tournament.slug)
    |> assign(:tournament_title, tournament.title)
    |> assign(:items, [])
    |> assign_bracket_and_seeding_page_item()
    |> assign_participants_page_item(number_of_participants)
    |> assign_stream_item(tournament)
    |> assign_tournament_contribution_item(tournament)
    |> assign_tournament_page_item()
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    %{
      tournament: tournament,
      current_user: current_user,
      live_action: live_action,
      can_manage_tournament: can_manage_tournament,
      number_of_participants: number_of_participants
    } = assigns

    socket
    |> assign(:live_action, live_action)
    |> assign(:can_manage_tournament, can_manage_tournament)
    |> assign(:tournament_slug, tournament.slug)
    |> assign(:tournament_title, tournament.title)
    |> assign(:items, [])
    |> assign_roster_invites_page_item(tournament, current_user)
    |> assign_settings_page_item()
    |> assign_participants_page_item(number_of_participants)
    |> assign_bracket_and_seeding_page_item()
    |> assign_matches_and_results_page_item()
    |> assign_stream_item(tournament)
    |> assign_tournament_contribution_item(tournament)
    |> assign_tournament_page_item()
    |> assign_player_dashboard_item(tournament, current_user)
    |> assign_dashboard_page_item()
    |> then(&{:ok, &1})
  end

  defp is_push_patch?(live_action) do
    live_action in TournamentPageLive.Show.live_actions()
  end

  defp is_push_patch?(new_live_action, live_action) do
    is_push_patch?(new_live_action) and is_push_patch?(live_action)
  end

  defp assign_tournament_contribution_item(socket, %{prize_strategy: :prize_distribution}) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
    new_live_action = :contribution

    tournament_contribution_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: ~p"/t/#{tournament_slug}/contribution",
      title: "Contribution",
      mobile_title: "Contribution"
    }

    update(socket, :items, &[tournament_contribution_item | &1])
  end

  defp assign_tournament_contribution_item(socket, _tournament), do: socket

  defp assign_stream_item(socket, tournament) do
    tournament = Repo.preload(tournament, :social_media_links)

    any_streaming_links =
      Enum.reduce_while(tournament.social_media_links, false, fn link, _ ->
        case SocialMediaLink.add_type(link) do
          %{type: :stream} -> {:halt, true}
          _ -> {:cont, false}
        end
      end)

    if tournament.status in [:in_progress, :under_review, :finished] and any_streaming_links do
      %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
      new_live_action = :stream

      tournament_stream_page_item = %{
        push_patch: is_push_patch?(new_live_action, live_action),
        url: ~p"/t/#{tournament_slug}/stream",
        title: "Stream",
        mobile_title: "Stream",
        selected: live_action == new_live_action
      }

      update(socket, :items, &[tournament_stream_page_item | &1])
    else
      socket
    end
  end

  defp assign_player_dashboard_item(socket, _tournament, nil), do: socket

  defp assign_player_dashboard_item(socket, tournament, current_user) do
    if Tournaments.is_user_participating_in_tournament?(tournament, current_user) do
      %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
      new_live_action = :player_dashboard

      my_tournament_page_item = %{
        push_patch: is_push_patch?(new_live_action, live_action),
        selected: live_action == new_live_action,
        url: "/tournament/#{tournament_slug}/player-dashboard",
        title: "Player Dashboard",
        mobile_title: "Player"
      }

      update(socket, :items, &[my_tournament_page_item | &1])
    else
      socket
    end
  end

  defp assign_roster_invites_page_item(socket, _tournament, nil), do: socket

  defp assign_roster_invites_page_item(socket, tournament, current_user) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
    new_live_action = :invites

    tournament_invitation =
      Tournaments.get_users_tournament_pending_invitation(current_user, tournament)

    party_invitations = Strident.Rosters.get_users_roster_invites(tournament.id, current_user)

    number_of_pending_invitations =
      Enum.count(party_invitations, &(&1.status == :pending)) +
        if is_nil(tournament_invitation), do: 0, else: 1

    roster_invites_page_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: ~p"/tournament/#{tournament_slug}/invitations",
      title: "Invites",
      mobile_title: "Invites",
      number_of_updates: number_of_pending_invitations
    }

    update(socket, :items, &[roster_invites_page_item | &1])
  end

  defp assign_dashboard_page_item(%{assigns: %{can_manage_tournament: false}} = socket),
    do: socket

  defp assign_dashboard_page_item(socket) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
    new_live_action = :dashboard

    dashboard_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: "/tournament/#{tournament_slug}/dashboard",
      title: "Dashboard",
      mobile_title: "Dashboard"
    }

    update(socket, :items, &[dashboard_item | &1])
  end

  defp assign_tournament_page_item(socket) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
    new_live_action = :show

    tournament_page_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: Routes.tournament_show_pretty_path(socket, :show, tournament_slug),
      title: "Tournament Page",
      mobile_title: "Info"
    }

    update(socket, :items, &[tournament_page_item | &1])
  end

  defp assign_matches_and_results_page_item(%{assigns: %{can_manage_tournament: false}} = socket),
    do: socket

  defp assign_matches_and_results_page_item(%{assigns: %{can_manage_tournament: true}} = socket) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns

    new_live_action = :matches_and_results

    matches_and_results_page_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: Routes.tournament_matches_and_results_path(socket, :index, tournament_slug),
      title: "Matches & Results",
      mobile_title: "Matches"
    }

    update(socket, :items, &[matches_and_results_page_item | &1])
  end

  defp assign_bracket_and_seeding_page_item(socket) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
    new_live_action = :bracket_and_seeding

    page_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament_slug),
      icon: :brackets,
      title: "Bracket & Seeding",
      mobile_title: "Bracket"
    }

    update(socket, :items, &[page_item | &1])
  end

  defp assign_participants_page_item(socket, number_of_participants) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
    new_live_action = :participants

    participants_page_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: Routes.tournament_page_show_path(socket, new_live_action, tournament_slug),
      title: "Participants (#{number_of_participants})",
      mobile_title: "Participants"
    }

    update(socket, :items, &[participants_page_item | &1])
  end

  defp assign_settings_page_item(%{assigns: %{can_manage_tournament: false}} = socket),
    do: socket

  defp assign_settings_page_item(socket) do
    %{tournament_slug: tournament_slug, live_action: live_action} = socket.assigns
    new_live_action = :settings

    settings_page_item = %{
      push_patch: is_push_patch?(new_live_action, live_action),
      selected: live_action == new_live_action,
      url: "/tournament/#{tournament_slug}/settings",
      title: "Settings",
      mobile_title: "Settings"
    }

    update(socket, :items, &[settings_page_item | &1])
  end

  attr(:push_patch, :boolean, required: true)
  attr(:url, :string, required: true)
  attr(:title, :string, required: true)
  attr(:mobile_title, :string, required: true)
  attr(:index, :integer, required: true)
  attr(:selected, :boolean, default: false)
  attr(:number_of_updates, :integer, default: 0)

  def menu_item(assigns) do
    assigns = Map.put_new(assigns, :push_patch, false)

    ~H"""
    <li>
      <.link
        :if={not @push_patch}
        id={"tournament-overview-link-#{@index}"}
        navigate={@url}
        class={[
          "flex items-center justify-between gap-1 px-2 py-1",
          if(@selected,
            do: "text-primary rounded-lg",
            else: "text-white rounded-lg hover:text-primary"
          )
        ]}
        phx-hook={if(@selected, do: "ScrollIntoView")}
      >
        <.hyu title={@title} mobile_title={@mobile_title} number_of_updates={@number_of_updates} />
      </.link>
      <.link
        :if={@push_patch}
        id={"tournament-overview-patch-link-#{@index}"}
        patch={@url}
        class={[
          "flex items-center justify-between px-2 py-1",
          if(@selected,
            do: "text-primary rounded-lg",
            else: "text-white rounded-lg hover:text-primary"
          )
        ]}
        phx-hook={if(@selected, do: "ScrollIntoView")}
      >
        <.hyu title={@title} mobile_title={@mobile_title} number_of_updates={@number_of_updates} />
      </.link>
    </li>
    """
  end

  attr(:title, :string, required: true)
  attr(:mobile_title, :string, required: true)
  attr(:number_of_updates, :integer, default: 0)

  defp hyu(assigns) do
    ~H"""
    <div class="flex gap-2">
      <div class="hidden text-center md:line-clamp-2"><%= @title %></div>
      <div class="text-center line-clamp-2 md:hidden"><%= @mobile_title %></div>

      <div
        :if={@number_of_updates > 0}
        class="hidden px-2 rounded-full bg-secondary text-secondary-dark animate-pulse md:block"
      >
        <%= @number_of_updates %>
      </div>
    </div>
    """
  end
end
