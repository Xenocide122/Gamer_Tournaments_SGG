defmodule StridentWeb.Live.NavbarLive.Components.Location do
  @moduledoc """
  This compenent adds a widget to the navbar to provide location information.
  """

  use Phoenix.LiveComponent

  import StridentWeb.Common.SvgUtils

  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div id="location" class="relative">
      <button
        id="location-flyout"
        class="inline-flex items-center gap-x-1 text-sm font-semibold leading-6 text-primary"
        aria-expanded="false"
        phx-click={JS.toggle(to: "#location-fly-out")}
        phx-click-away={JS.hide(to: "#location-fly-out")}
      >
        <.svg
          :if={@can_play and @can_wager}
          icon={:location}
          width="24"
          height="24"
          class="h-full mt-1"
        />
        <.svg
          :if={@can_play and not @can_wager}
          icon={:location}
          width="24"
          height="24"
          class="text-yellow-400 h-full mt-1"
        />
        <.svg
          :if={not @can_play and @can_wager}
          icon={:location}
          width="24"
          height="24"
          class="text-yellow-400 h-full mt-1"
        />
        <.svg
          :if={not @can_play and not @can_wager}
          icon={:location}
          width="24"
          height="24"
          class="text-secondary h-full mt-1"
        />
      </button>
      <div
        id="location-fly-out"
        class="hidden absolute z-10 mt-4 w-screen max-w-max px-4 -translate-x-3/4"
      >
        <div class="w-screen max-w-md flex-auto overflow-hidden rounded-xl bg-gray-900 text-md leading-6 shadow-lg ring-1 ring-gray-900/5 right-20">
          <div class="p-4">
            <div class="group relative flex gap-x-6 rounded-lg p-4">
              <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center">
                <.svg icon={:house} width="32" height="32" class="h-full mt-1" />
              </div>
              <div>
                <div class="font-semibold text-gray-50">
                  Location <span class="absolute inset-0"></span>
                </div>
                <p class="text-gray-50">
                  <%= @ip_location.region_name %>, <%= @ip_location.country_name %>
                </p>
              </div>
            </div>
            <div class="group relative flex gap-x-6 rounded-lg p-4">
              <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center">
                <.svg :if={@can_play} icon={:prize} width="32" height="32" class="h-full mt-1" />
                <.svg
                  :if={not @can_play}
                  icon={:prize}
                  width="32"
                  height="32"
                  class="text-secondary h-full mt-1"
                />
              </div>
              <div>
                <div class="text-gray-50">Play</div>
                <span class="absolute inset-0"></span>

                <p :if={@can_play} class="text-gray-50">
                  You can play in Tournaments with entry fees And prizes
                </p>
                <p :if={not @can_play} class="text-gray-50">
                  You cannot play in Tournaments with entry fees or prizes
                </p>
              </div>
            </div>
            <div class="group relative flex gap-x-6 rounded-lg p-4">
              <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center">
                <.svg :if={@can_wager} icon={:bank_notes} width="32" height="32" class="h-full mt-1" />
                <.svg
                  :if={not @can_wager}
                  icon={:bank_notes}
                  width="32"
                  height="32"
                  class="text-secondary h-full mt-1"
                />
              </div>
              <div>
                <div class="text-gray-50">Challenge</div>
                <span class="absolute inset-0"></span>

                <p :if={@can_wager} class="text-gray-50">You can challenge players for money</p>
                <p :if={not @can_wager} class="text-gray-50">
                  You cannot challenge players for money
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
