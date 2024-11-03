defmodule StridentWeb.TournamentLive.Create.CustomTournament do
  @moduledoc """
  The "custom tournament" page, where user can get info for creation of custom tournament.
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(_assigns, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="ml-20">
      <button
        id="back-button"
        type="button"
        class="font-bold px-2 md:px-8 py-3 text-base !no-underline uppercase border-white border-2 rounded-lg btn--primary font-display md:text-3xl text-center align-center"
        phx-click="back-to-landing"
      >
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-7 w-7 mr-0"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d={StridentWeb.Common.SvgUtils.path(:chevron_left)}
              clip-rule="evenodd"
            />
          </svg>
          Back to landing page
        </div>
      </button>

      <h3 class="text-white w-full">
        Contact Us
      </h3>

      <h4 class="text-primary w-full">
        New Stride Users
      </h4>
      <p class="mb-10">
        If you have any questions about running your tournament,
        or are interested in a custom option for your event, please email us at <a
          class="text-primary"
          href="mailto: support@stride.gg"
        >support@stride.gg</a>.
      </p>

      <h4 class="text-primary w-full">
        Existing Stride Users
      </h4>
      <p class="mb-10">
        For technical support and other questions about your existing tournament, please reach out to <a
          class="text-primary"
          href="mailto: support@stride.gg"
        >support@stride.gg</a>.
      </p>
    </div>
    """
  end
end
