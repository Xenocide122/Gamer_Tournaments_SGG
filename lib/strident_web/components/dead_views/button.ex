defmodule StridentWeb.DeadViews.Button do
  @moduledoc false
  use Phoenix.Component
  import StridentWeb.Common.SvgUtils

  @doc """
  Renders a button.

  ## Examples

      <.button id="send-button">Send!</.button>
      <.button id="send-button" phx-click="go" class="ml-2">Send!</.button>
  """

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:button_type, :atom, default: nil)
  attr(:extra, :global, include: ["disabled", "type", "form", "value", "phx_click"])
  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      id={@id}
      class={[
        @class,
        class_type(@button_type),
        "inline-block cursor-pointer font-medium border py-2.5 px-4 select-none disabled:opacity-50"
      ]}
      {@extra}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr(:class, :string, default: "")
  attr(:hide, :boolean, default: false)
  attr(:extra, :global, include: ["disabled", "type", "form"])
  slot(:inner_block, required: true)

  def back_button(assigns) do
    ~H"""
    <div class={["link text-center mb-2 mb:mb-0", @class, if(@hide, do: "hidden")]} {@extra}>
      <div class="flex items-center">
        <.svg icon={:chevron_left} class="fill-current" /><%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:button_class, :any, default: nil)
  attr(:button_type, :atom, default: nil)
  attr(:extra, :global, include: ["disabled", "type", "form", "value", "phx_click"])
  attr(:caption_class, :any, default: nil)
  slot(:inner_block, required: true)
  slot(:caption_block)

  def button_with_caption(assigns) do
    ~H"""
    <div class="flex flex-col justify-start gap-2">
      <.button id={@id} class={@button_class} button_type={@button_type} {@extra}>
        <%= render_slot(@inner_block) %>
      </.button>
      <p class={["text-xs", @caption_class]}>
        <%= render_slot(@caption_block) %>
      </p>
    </div>
    """
  end

  defp class_type(:primary), do: "btn btn--primary btn--wide"

  defp class_type(:primary_default), do: "btn btn--primary"

  defp class_type(:primary_ghost), do: "text-white btn btn--primary-ghost btn--wide"

  defp class_type(:secondary), do: "btn btn--secondary btn--wide"

  defp class_type(:secondary_default), do: "btn btn--secondary"

  defp class_type(:secondary_dark),
    do: "text-white uppercase bg-secondary-dark border-secondary-dark"

  defp class_type(:secondary_ghost), do: "text-white btn btn--secondary-ghost btn--wide"

  defp class_type(:grey_light), do: "border-grey-light text-grey-light"

  defp class_type(:clear_primary), do: "text-primary border-none uppercase"

  defp class_type(_), do: ""
end
