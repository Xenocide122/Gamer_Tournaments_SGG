defmodule StridentWeb.NavbarLive.Compoenets.Widgets do
  @moduledoc """
  Components for Navbar.
  """
  use Phoenix.Component

  @doc """
  Returns links for mobile and web version.

  Accepts following attributes and slots:

  * `:id` - id of the link, for mobile we add
  `-mobile` at the end of the ID
  * `:navigation` - path to which this link needs to lead to
  * `:title` - navigation title
  * `:icon` - slot for web to show icons

  ## Example

       <.navbar_link id="my-profile-navbar-link" navigate={~p"/user/slug"}>
         <.svg
           icon={:user}
           width="24"
           height="24"
           class="bg-transparent stroke-current stroke-2"
         />
         <span>My Profile</span>
        </.navbar_link>
  """
  attr(:id, :string, required: true)
  attr(:rest, :global, include: ["navigate", "href", "method"])
  slot(:inner_block, doc: "Slot")

  def navbar_link(assigns) do
    ~H"""
    <.link
      id={@id}
      class="flex items-center space-x-2 px-5 py-2.5 hover:bg-blackish hover:text-primary"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
