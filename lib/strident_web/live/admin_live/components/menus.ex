defmodule StridentWeb.AdminLive.Components.Menus do
  @moduledoc """
  Menu components for admin section
  """
  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: StridentWeb.Endpoint, router: StridentWeb.Router

  @pages [
    :home,
    :users,
    :dupe_emails,
    :games,
    :homepage,
    :tournament_cards,
    :features,
    :cluster,
    :horde,
    :reports,
    :payouts
  ]

  attr(:selected, :atom, required: true)
  attr(:pages, :list, default: @pages)

  def tabs(assigns) do
    ~H"""
    <nav class="flex -mb-px space-x-4 overflow-auto">
      <.link
        :for={page <- @pages}
        navigate={"/admin/#{page}"}
        class={[
          "flex items-center my-5 font-medium border-b-2 border-transparent",
          if(page == @selected, do: "text-primary border-primary")
        ]}
      >
        <%= Phoenix.Naming.humanize(page) %>
      </.link>
    </nav>
    """
  end
end
