defmodule StridentWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com), using the
  [heroicons_elixir](https://github.com/mveytsman/heroicons_elixir) project.
  """
  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: StridentWeb.Endpoint, router: StridentWeb.Router
  import StridentWeb.Common.SvgUtils
  alias Phoenix.LiveView.JS
  # import StridentWeb.Gettext
  # import StridentWeb.DeadViews.Button
  import StridentWeb.DeadViews.Image

  @doc """
  Renders a filter.

  ## Example

        <.filter id="filter" />
        <.filter id="filter" placeholder="Search by" />
  """
  attr(:id, :string, required: true)
  attr(:placeholder, :string, default: "Search")
  attr(:phx_debounce, :integer, default: 1000)

  def filter(assigns) do
    ~H"""
    <div id={@id} class="flex items-center">
      <.svg
        id={[@id, "-button"]}
        icon={:search}
        width="24"
        height="24"
        class="cursor-pointer fill-white"
        phx-click={
          JS.toggle(to: "##{@id}-form-full", display: "flex")
          |> JS.remove_class("fill-white", to: "##{@id}-button")
          |> JS.add_class("fill-primary", to: "##{@id}-button")
          |> JS.focus(to: "##{@id}-input")
        }
      />

      <div id={[@id, "-form-full"]} class="items-center hidden">
        <form
          id={[@id, "-form"]}
          phx-submit="search"
          phx-change="search"
          phx-debounce={@phx_debounce}
          class="w-full"
        >
          <input
            id={[@id, "-input"]}
            name="search_term"
            type="text"
            class="w-64 px-0 py-0 bg-transparent border-0 border-b border-primary focus:border-primary focus:ring-0"
            placeholder={@placeholder}
          />
        </form>

        <.svg
          icon={:close}
          width="24"
          height="24"
          class="cursor-pointer fill-primary"
          phx-click={
            JS.toggle(to: "##{@id}-form-full", display: "flex")
            |> JS.remove_class("fill-primary", to: "##{@id}-button")
            |> JS.add_class("fill-white", to: "##{@id}-button")
            |> JS.push("close-search")
          }
        />
      </div>
    </div>
    """
  end

  attr(:total_pages, :integer, required: true)
  attr(:current_page, :integer, required: true)

  def pagination(assigns) do
    ~H"""
    <div :if={@total_pages > 1} class="flex justify-between pt-4">
      <.svg
        icon={:chevron_left}
        height="40"
        width="40"
        class="fill-primary"
        phx-click="previous-page"
      />

      <div class="flex items-center justify-center gap-2">
        <.svg
          :for={index <- 1..@total_pages}
          :if={@total_pages <= 30}
          icon={:x_circle}
          height="15"
          width="15"
          class={[
            "cursor-pointer",
            if(@current_page == index, do: "fill-primary", else: "fill-grey-light")
          ]}
          phx-click="go-to-page"
          phx-value-page={index}
        />

        <p :if={@total_pages > 30} class="text-xs text-grey-light"><%= @current_page %></p>
      </div>

      <.svg icon={:chevron_right} height="40" width="40" class="fill-primary" phx-click="next-page" />
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :string, default: "")
  attr(:modal_class, :string, default: "right-0")
  attr(:show_button, :boolean, default: true)
  slot(:button_content, required: true, doc: "Render button")
  slot(:items, required: true, doc: "Items to render")

  def dropdown(assigns) do
    ~H"""
    <div
      id={@id}
      class={["group relative flex items-center", @class]}
      phx-click-away={JS.hide(to: "##{@id}-dropdown-menu", transition: "ease-out duration-150")}
    >
      <button phx-click={
        JS.toggle(
          to: "##{@id}-dropdown-menu",
          in: {"ease-out duration-150", "opacity-0", "opacity-100"},
          out: {"ease-out duration-150", "opacity-100", "opacity-0"}
        )
      }>
        <%= render_slot(@button_content) %>
      </button>

      <div
        id={"#{@id}-dropdown-menu"}
        class={[
          "absolute only:z-10 hidden overflow-auto w-max h-auto max-h-96 md:h-auto md:max-h-screen border shadow-lg
          md:w-60 top-full md:top-full bg-grey-medium border-grey-light/10 md:rounded-xl ",
          @modal_class
        ]}
      >
        <div class="py-2">
          <%= for item <- @items do %>
            <%= render_slot(item) %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :string, default: "")
  attr(:modal_class, :string, default: "right-0")
  slot(:button_content, required: true, doc: "Render button")
  slot(:items, required: true, doc: "Items to render")

  def dropdown_mobile(assigns) do
    ~H"""
    <div
      id={@id}
      class={["flex items-center", @class]}
      phx-click-away={JS.hide(to: "##{@id}-dropdown-menu", transition: "ease-out duration-150")}
    >
      <button phx-click={
        JS.toggle(
          to: "##{@id}-dropdown-menu",
          in: {"ease-out duration-150", "opacity-0", "opacity-100"},
          out: {"ease-out duration-150", "opacity-100", "opacity-0"}
        )
      }>
        <%= render_slot(@button_content) %>
      </button>
    </div>

    <div id={"#{@id}-dropdown-menu"} class={["hidden space-y-1 px-2 pt-2 pb-3 sm:px-3", @modal_class]}>
      <div class="py-2">
        <%= for item <- @items do %>
          <%= render_slot(item) %>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :string, default: "")
  slot(:items, required: true, doc: "Items to render")

  def dropdown_items(assigns) do
    ~H"""
    <div
      id={"#{@id}-dropdown-menu"}
      class={[
        "only:z-10 hidden overflow-auto w-60 h-auto max-h-screen border shadow-lg
        bg-grey-medium border-grey-light/10 rounded-xl",
        @class
      ]}
    >
      <div class="py-2">
        <%= for item <- @items do %>
          <%= render_slot(item) %>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :string, default: "")
  slot(:items, required: true, doc: "Items to render")

  def dropdown_mobile_items(assigns) do
    ~H"""
    <div
      id={"#{@id}-dropdown-menu"}
      class={[
        "absolute hidden w-full h-screen !p-0 max-h-screen border-none shadow-lg bg-blackish/90 only:z-10 top-full overflow-scroll",
        @class
      ]}
    >
      <div :for={item <- @items} class="mx-4">
        <%= render_slot(item) %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:current_view, :any, default: nil)
  attr(:current_module, :any, default: nil)
  attr(:class, :string, default: "")
  attr(:rest, :global, include: ~w(navigate method href))
  slot(:inner_block, required: true)

  def navbar_button(assigns) do
    ~H"""
    <.link
      id={@id}
      class={[
        "flex items-center my-5 font-medium border-b-2 border-transparent hover:text-primary",
        if(!!@current_view and !!@current_module and @current_view == @current_module,
          do: "text-primary border-primary"
        ),
        @class
      ]}
      {@rest}
    >
      <div class="hidden lg:block font-medium text-xl"><%= render_slot(@inner_block) %></div>
      <div class="lg:hidden font-medium text-xl"><%= render_slot(@inner_block) %></div>
    </.link>
    """
  end

  attr(:id, :string, required: true)
  attr(:avatar_url, :string, required: true)
  attr(:display_name, :string, required: true)
  attr(:unread_notifications, :integer, required: true)
  attr(:rest, :global, include: ["phx-click"])
  attr(:class, :string, default: "")

  def navbar_user_icon_button(assigns) do
    ~H"""
    <button id={@id} class={@class} {@rest}>
      <div class="flex items-center">
        <div class="relative">
          <.image
            id={"#{@id}-navbar-user-logo"}
            image_url={@avatar_url}
            alt={@display_name}
            class={"!w-10 !h-10 mr-1 rounded-full #{if(@unread_notifications > 0, do: "border border-secondary animate-pulse")}"}
            height={40}
            width={40}
          />

          <div
            :if={@unread_notifications > 0}
            class="absolute bottom-0 right-0 inline-flex items-center justify-center flex-shrink-0 w-4 h-4 text-xs rounded-full bg-secondary-dark dark:bg-secondary"
          >
            <%= @unread_notifications %>
          </div>
        </div>

        <.svg
          id={"#{@id}-menu-chevron-right"}
          icon={:chevron_right}
          width="20"
          height="20"
          class="fill-current"
        />
      </div>
    </button>
    """
  end

  attr(:id, :string, required: true)
  attr(:image, :string, default: Strident.Accounts.return_default_avatar())
  attr(:name, :string, default: "")
  attr(:class, :string, default: "")
  attr(:rest, :global, include: ~w())
  attr(:navigate, :any, default: nil)

  def player_card(%{navigate: nil} = assigns) do
    ~H"""
    <button class={[
      "relative flex items-center justify-center border-2 w-[177px] h-[110px] opacity-50
        lg:h-[160px] lg:w-[256px] border-primary rounded-xl bg-grey-medium cursor-auto",
      @class
    ]}>
      <div class="flex flex-col items-center justify-center gap-2">
        <.image
          id={"#{@id}-hover-card-image"}
          image_url={@image}
          alt={@name}
          class="rounded-full lg:w-[64px] lg:h-[64px] w-[48px] h-[48px]"
          height={85}
          width={85}
        />
        <p class="text-primary"><%= @name %></p>
      </div>
    </button>
    """
  end

  def player_card(assigns) do
    ~H"""
    <button
      class={[
        "relative flex items-center justify-center transition duration-500 transform border-2 w-[177px] h-[110px]
         lg:h-[160px] lg:w-[256px] border-primary rounded-xl bg-grey-medium hover:scale-110 hover:drop-shadow-xl",
        @class
      ]}
      phx-click={JS.navigate(@navigate)}
    >
      <div class="flex flex-col items-center justify-center gap-2">
        <.image
          id={"#{@id}-hover-card-image"}
          image_url={@image}
          alt={@name}
          class="rounded-full lg:w-[64px] lg:h-[64px] w-[48px] h-[48px]"
          height={85}
          width={85}
        />
        <p class="text-primary"><%= @name %></p>
      </div>
    </button>
    """
  end
end
