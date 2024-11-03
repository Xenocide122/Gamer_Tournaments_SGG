defmodule StridentWeb.TournamentRegistrationLive.Components.HelperComponent do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.HTML.Form
  alias Strident.Prizes

  attr(:prize_strategy, :atom, required: true)
  attr(:prize_pool, :map, default: %{})
  attr(:prize_distribution, :map, default: %{})

  def prize_pool(%{prize_strategy: :prize_distribution, prize_distribution: map} = assigns)
      when map_size(map) == 0 do
    ~H"""

    """
  end

  def prize_pool(%{prize_strategy: :prize_distribution} = assigns) do
    ~H"""
    <div class="divide-y divide-black">
      <.render_prize :for={{rank, percent} <- @prize_distribution} rank={rank}>
        <%= percent %>%
      </.render_prize>
    </div>
    """
  end

  def prize_pool(%{prize_strategy: :prize_pool, prize_pool: map} = assigns)
      when map_size(map) == 0 do
    ~H"""

    """
  end

  def prize_pool(%{prize_strategy: :prize_pool} = assigns) do
    ~H"""
    <h6 class="mb-2 uppercase text-grey-light">
      Prize Pool
    </h6>
    <div class="divide-y divide-black">
      <.render_prize :for={{rank, money} <- @prize_pool} rank={rank}><%= money %></.render_prize>
    </div>
    """
  end

  attr(:rank, :integer, required: true)
  slot(:inner_block, required: true)

  defp render_prize(assigns) do
    ~H"""
    <div class="grid grid-cols-2 py-2 text-sm">
      <div class="text-grey-light">
        <%= Prizes.format_prize_rank(@rank) %>
      </div>

      <div class="text-right">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:disabled, :boolean, default: false)
  attr(:form, :any, required: true)
  attr(:field_name, :any, required: true)
  attr(:checked, :boolean, required: true)
  attr(:hidden_values, :any, default: %{})
  slot(:label_slot, required: true)

  def checkbox(assigns) do
    ~H"""
    <div id={@id} class="flex items-center">
      <%= checkbox(@form, @field_name,
        checked: @checked,
        disabled: @disabled,
        class: "h-4 w-4 text-primary focus:ring-indigo-500 border-gray-300 rounded",
        id: "#{@id}-checkbox"
      ) %>
      <%= render_slot(@label_slot) %>
      <%= for {field, value} <- @hidden_values do %>
        <%= hidden_input(@form, field, value: value, id: "#{@id}") %>
      <% end %>
    </div>
    """
  end
end
