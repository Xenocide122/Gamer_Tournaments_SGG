defmodule StridentWeb.Components.PresetMoneyAmounts do
  @moduledoc false
  use StridentWeb, :live_component

  @defaults %{
    preset_amounts: [10, 20, 50, 100, 200, 500],
    class: "",
    target: nil,
    max_amount: Money.new(:USD, "Inf"),
    min_amount: Money.new(:USD, 0)
  }

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(Map.merge(@defaults, assigns))
    |> assign_preset_monies()
    |> then(&{:ok, &1})
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-2 md:grid-cols-3 gap-4 md:gap-6 mb-8 items-start">
      <%= for preset_money <- @preset_monies do %>
        <%= if disable_button?(preset_money, @max_amount, @min_amount) do %>
          <button type="button" class="btn bg-transparent py-4 cursor-not-allowed text-grey-light">
            <%= preset_money %>
          </button>
        <% else %>
          <button
            phx-value-amount={preset_money.amount}
            phx-value-currency={preset_money.currency}
            phx-target={@target || @myself}
            type="button"
            phx-click="set-amount"
            class="btn bg-transparent py-4 btn--primary text-primary"
          >
            <%= preset_money %>
          </button>
        <% end %>
      <% end %>
    </div>
    """
  end

  @spec assign_preset_monies(Socket.t()) :: Socket.t()
  def assign_preset_monies(%{assigns: %{preset_amounts: preset_amounts}} = socket) do
    assign_new(socket, :preset_monies, fn -> Enum.map(preset_amounts, &Money.new(:USD, &1)) end)
  end

  @spec disable_button?(Money.t(), Money.t(), Money.t()) :: boolean()
  def disable_button?(money, max_amount, min_amount) do
    Money.compare(money, max_amount) == :gt or Money.compare(money, min_amount) == :lt
  end
end
