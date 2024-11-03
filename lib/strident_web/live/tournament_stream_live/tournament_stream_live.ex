defmodule StridentWeb.TournamentStreamLive do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Extension.NaiveDateTime
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.Tournaments

  @tournament_preloads [social_media_links: [], participants: []]

  @impl true
  def render(assigns) do
    ~H"""
    <.container id={"tournament-settings-#{@tournament.id}"} class="relative">
      <:side_menu>
        <.live_component
          id={"side-menu-#{@tournament.id}"}
          module={StridentWeb.TournamentManagement.Components.SideMenu}
          can_manage_tournament={@can_manage_tournament}
          tournament={@tournament}
          number_of_participants={
            Enum.count(@tournament.participants, &(&1.status in Tournaments.on_track_statuses()))
          }
          live_action={@team_site}
          current_user={@current_user}
          timezone={@timezone}
          locale={@locale}
        />
      </:side_menu>

      <section :if={not is_nil(@stream_link)} id="stream" class="px-4 md:px-32">
        <h3 class="mb-6 leading-none tracking-normal uppercase font-display">
          Live Stream
        </h3>

        <div class="flex justify-start">
          <%= case @stream_link.brand do %>
            <% :twitch -> %>
              <div id="twitch-embed" phx-hook="TwitchEmbed" data-channel-name={@stream_link.handle}>
              </div>
            <% :youtube -> %>
              <iframe
                width="854"
                height="480"
                src={"#{@stream_link.user_input}"}
                frameborder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
              >
              </iframe>
          <% end %>
        </div>
      </section>
    </.container>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tournament = Tournaments.get_tournament_with_preloads_by([slug: slug], @tournament_preloads)

    can_manage_tournament =
      Tournaments.can_manage_tournament?(socket.assigns.current_user, tournament)

    socket
    |> assign(:tournament, tournament)
    |> assign(:team_site, :stream)
    |> assign(:can_manage_tournament, can_manage_tournament)
    |> assign_first_stream_link()
    |> then(&{:ok, &1})
  end

  def assign_first_stream_link(socket) do
    %{assigns: %{tournament: tournament}} = socket

    tournament.social_media_links
    |> only_stream_links()
    |> Enum.sort_by(& &1.inserted_at, fn
      nil, _ -> false
      _, nil -> true
      time_1, time_2 -> NaiveDateTime.compare(time_1, time_2) == :lt
    end)
    |> Enum.at(0)
    |> then(&assign(socket, :stream_link, &1))
  end

  defp only_stream_links(social_media_links) do
    Enum.reduce(social_media_links, [], fn link, links ->
      case SocialMediaLink.add_type(link) do
        %{type: :stream} -> [SocialMediaLink.add_user_input(link) | links]
        _ -> links
      end
    end)
  end
end
