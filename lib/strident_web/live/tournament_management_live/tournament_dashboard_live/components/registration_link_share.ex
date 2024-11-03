defmodule StridentWeb.TournamentDashboardLive.Components.RegistrationLinkShare do
  @moduledoc false
  use StridentWeb, :live_component

  alias Strident.UrlGeneration
  alias StridentWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- <div class="rounded-lg bg-primary shadow-md shadow-primary p-[1px] mb-8 lg:mb-0 basis-0 grow lg:h-48"> --%>
    <div class="flex-auto">
      <.wide_card colored={true}>
        <div class="h-48 max-h-full rounded-lg bg-blackish">
          <div class="flex items-center">
            <img
              width="40"
              height="40"
              class="mr-1 rounded-b max-h-20"
              src="/images/font-awesome/link.svg"
              alt="users"
            />
            <h4 class="uppercase text-primary">Registration Link</h4>
          </div>

          <div class="flex flex-col items-center p-4">
            <form class="flex flex-col justify-center mx-2">
              <input
                id={"copyable-tournament-registration-link-id-#{@tournament.id}"}
                class="shadow-md form-input max-h-9"
                name="tournament_link"
                type="text"
                value={@tournament_link}
                autocomplete="off"
                placeholder="Registration Link"
              />

              <span id="link-copied" class="hidden">
                Link copied!
              </span>

              <div id="copy-button" class="flex justify-center mt-6">
                <.button
                  id={"copy-tournament-registration-button-#{@tournament.id}"}
                  button_type={:primary}
                  class="py-1"
                  type="button"
                  phx-click={
                    JS.dispatch("grilla:clipcopyinput",
                      to: "#copyable-tournament-registration-link-id-#{@tournament.id}"
                    )
                    |> JS.remove_class("hidden", to: "#link-copied")
                    |> JS.remove_class("mt-6", to: "#copy-button")
                    |> JS.add_class("border-primary text-primary shadow-primary",
                      to: "#copyable-tournament-registration-link-id-#{@tournament.id}"
                    )
                  }
                >
                  Copy Link
                </.button>
              </div>
            </form>
          </div>
        </div>
      </.wide_card>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{tournament: tournament}, socket) do
    socket
    |> assign(:tournament, tournament)
    |> assign_tournament_link()
    |> then(&{:ok, &1})
  end

  def assign_tournament_link(socket) do
    %{assigns: %{tournament: tournament}} = socket

    StridentWeb.Endpoint
    |> Routes.tournament_show_path(:show, tournament)
    |> UrlGeneration.absolute_path()
    |> then(&assign(socket, :tournament_link, &1))
  end
end
