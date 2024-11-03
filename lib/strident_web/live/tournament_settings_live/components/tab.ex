defmodule StridentWeb.TournamentSettingsLive.Components.Tab do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts.User
  alias StridentWeb.TournamentSettingsLive
  @base_class "text-center md:text-3xl md:font-display uppercase border-b-2 mb-6"

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{page: page, current_user: current_user, tournament: tournament}, socket) do
    socket
    |> assign(:current_user, current_user)
    |> assign(:tournament, tournament)
    |> assign(:page, page)
    |> assign_links()
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="sticky z-40 border-b-2 border-grey-dark md:relative top-28 md:top-auto bg-blackish/90">
      <ul class="flex h-10 gap-8 overflow-x-scroll md:flex-wrap md:overflow-x-auto">
        <li :for={%{title: title, slug: slug, page: page} <- @links}>
          <.link
            id={"tournament-settings-tab-link-#{page}"}
            patch={Routes.live_path(@socket, TournamentSettingsLive, @tournament.slug, slug)}
            class={get_class(page, @page)}
            phx-hook={if page == @page, do: "ScrollIntoView", else: nil}
          >
            <%= title %>
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  def assign_links(socket) do
    %{current_user: current_user} = socket.assigns

    is_staff =
      case current_user do
        %User{is_staff: true} -> true
        _ -> false
      end

    links =
      [
        %{title: "Basic", slug: "basic-settings", page: :basic_settings},
        %{title: "Match", slug: "match-settings", page: :match_settings},
        %{title: "Stage", slug: "stage-settings", page: :stage_settings}
      ]
      |> then(
        &if(
          Application.get_env(:strident, :env) == :prod and
            is_nil(System.get_env("IS_STAGING")) and not is_staff,
          do: &1,
          else:
            &1 ++
              [%{title: "Restructure", slug: "brackets-structure", page: :brackets_structure}]
        )
      )
      |> then(
        &if(socket.assigns.tournament.status == :cancelled,
          do: &1,
          else:
            &1 ++
              [%{title: "Cancel", slug: "cancel-tournament", page: :cancel_tournament}]
        )
      )

    assign(socket, :links, links)
  end

  def get_class(:cancel_tournament, selected_page) do
    get_class(nil, selected_page) <> " text-secondary"
  end

  def get_class(page, page) do
    @base_class <> " active text-primary border-primary"
  end

  def get_class(_page, _selected_page) do
    @base_class <> "text-white border-transparent hover:text-primary hover:border-primary "
  end
end
