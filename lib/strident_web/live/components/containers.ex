defmodule StridentWeb.Components.Containers do
  @moduledoc """
  Container components. See /stylekit to view them in action.

  Optional props for all components:
  - `class`, :string

  Optional props for cards:
  - `colored`, :boolean, default `false`
  """

  use Phoenix.Component

  attr(:inner_class, :string, default: "")
  attr(:class, :string, default: "")
  attr(:colored, :boolean, default: false)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <.generic_card
      inner_class={@inner_class}
      colored={@colored}
      class={@class}
      base_class="card"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.generic_card>
    """
  end

  attr(:inner_class, :string, default: "")
  attr(:class, :string, default: "")
  attr(:colored, :boolean, default: false)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def wide_card(assigns) do
    ~H"""
    <.generic_card
      inner_class={@inner_class}
      colored={@colored}
      class={@class}
      base_class="card--wide"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.generic_card>
    """
  end

  attr(:inner_class, :string, default: "")
  attr(:class, :string, default: "")
  attr(:colored, :boolean, default: false)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tall_card(assigns) do
    ~H"""
    <.generic_card
      inner_class={@inner_class}
      colored={@colored}
      class={@class}
      base_class="card--tall"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.generic_card>
    """
  end

  attr(:class, :string, default: "")
  attr(:inner_class, :string, default: "")
  attr(:colored, :boolean, default: false)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def slim_card(assigns) do
    ~H"""
    <.generic_card
      inner_class={@inner_class}
      colored={@colored}
      class={@class}
      base_class="card--slim"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.generic_card>
    """
  end

  attr(:inner_class, :string, required: true)
  attr(:colored, :boolean, required: true)
  attr(:base_class, :string, required: true)
  attr(:class, :string, required: true)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  defp generic_card(assigns) do
    ~H"""
    <div :if={@colored} class={[@base_class, @class, "card--colored"]} {@rest}>
      <div class={[@inner_class, "px-0 py-0 card__inner rounded-2xl"]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>

    <div :if={!@colored} class={["", @base_class, @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def divider(assigns) do
    ~H"""
    <div class={"divider #{assigns[:class]}"} />
    """
  end
end
