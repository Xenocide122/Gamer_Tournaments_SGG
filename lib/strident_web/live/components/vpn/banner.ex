defmodule StridentWeb.Components.Vpn.Banner do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.VPN

  @impl true
  def mount(
        :not_mounted_at_router,
        %{
          "show_vpn_banner" => show_vpn_banner,
          "is_using_vpn" => is_using_vpn,
          "current_user_id" => current_user_id
        },
        socket
      ) do
    socket
    |> assign(:current_user_id, current_user_id)
    |> assign(show_vpn_banner: show_vpn_banner)
    |> assign(is_using_vpn: is_using_vpn)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("remove", _, socket) do
    VPN.hide_vpn_banner(socket.assigns.current_user_id)

    socket
    |> assign(show_vpn_banner: false)
    |> then(&{:noreply, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@show_vpn_banner} class="fixed inset-x-0 bottom-0">
        <div class="bg-red-900">
          <div class="mx-auto max-w-7xl py-3 px-3 sm:px-6 lg:px-8">
            <div class="flex flex-wrap items-center justify-center">
              <div class="flex w-0 flex-1 items-center">
                <span class="flex rounded-lg bg-red-600 p-2">
                  <!-- Heroicon name: outline/megaphone -->
                  <svg
                    class="h-6 w-6 text-white"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M10.34 15.84c-.688-.06-1.386-.09-2.09-.09H7.5a4.5 4.5 0 110-9h.75c.704 0 1.402-.03 2.09-.09m0 9.18c.253.962.584 1.892.985 2.783.247.55.06 1.21-.463 1.511l-.657.38c-.551.318-1.26.117-1.527-.461a20.845 20.845 0 01-1.44-4.282m3.102.069a18.03 18.03 0 01-.59-4.59c0-1.586.205-3.124.59-4.59m0 9.18a23.848 23.848 0 018.835 2.535M10.34 6.66a23.847 23.847 0 008.835-2.535m0 0A23.74 23.74 0 0018.795 3m.38 1.125a23.91 23.91 0 011.014 5.395m-1.014 8.855c-.118.38-.245.754-.38 1.125m.38-1.125a23.91 23.91 0 001.014-5.395m0-3.46c.495.413.811 1.035.811 1.73 0 .695-.316 1.317-.811 1.73m0-3.46a24.347 24.347 0 010 3.46"
                    />
                  </svg>
                </span>
                <p class="ml-3 truncate font-medium text-white">
                  <span class="hidden md:inline">
                    It seems you are using a VPN, this may restrict your ability to participate. For the best experience please turn off your VPN. Thanks!
                  </span>
                </p>
              </div>

              <div class="order-2 flex-shrink-0 sm:order-3 sm:ml-3">
                <button
                  type="button"
                  phx-click="remove"
                  class="-mr-1 flex rounded-md p-2 hover:bg-red-600 focus:outline-none focus:ring-1 focus:ring-red-700 sm:-mr-2"
                >
                  <span class="sr-only">Dismiss</span>
                  <!-- Heroicon name: outline/x-mark -->
                  <svg
                    class="h-6 w-6 text-white"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    aria-hidden="true"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
