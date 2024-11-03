defmodule StridentWeb.Components.Profile.Grid do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{profiles: profiles} = assigns, socket) do
    socket =
      socket
      |> copy_parent_assigns(assigns)
      |> assign_profiles(profiles)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4 md:gap-x-8 md:gap-y-8">
      <%= for profile <- @profiles do %>
        <.live_component
          id={"profile-grid-#{profile.id}"}
          module={StridentWeb.Components.Profile.Card}
          profile={profile}
          current_user={@current_user}
          timezone={@timezone}
          locale={@locale}
        />
      <% end %>
    </div>
    """
  end

  def assign_profiles(socket, profiles) do
    assign(socket, :profiles, profiles)
  end
end
