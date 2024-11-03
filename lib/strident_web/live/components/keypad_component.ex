defmodule StridentWeb.Components.KeypadComponent do
  @moduledoc false
  use Phoenix.Component
  import StridentWeb.DeadViews.Button
  alias StridentWeb.Common.MoneyInput

  attr(:selected_amount, :any, required: true)
  attr(:f, :any, required: true)
  attr(:target, :any, default: nil)
  attr(:locale, :any, required: true)
  attr(:timezone, :any, required: true)
  attr(:disable_till_amount, :any)

  attr(:amounts, :list,
    default: for(amount <- [5, 10, 15, 20, 50, 100], do: Money.new(:USD, amount))
  )

  def keypad(assigns) do
    ~H"""
    <div>
      <h6 class="uppercase text-grey-light">Amount</h6>
      <div class="grid grid-cols-3 gap-2 mt-2 rounded">
        <.button
          :for={%{amount: amount, currency: currency} = money <- @amounts}
          id={"amount-#{amount}"}
          class={[
            "py-2 text-center bg-grey-medium border-grey-medium rounded",
            show_selected_text(@selected_amount, money)
          ]}
          type="button"
          phx-click="select-amount"
          phx-value-amount={amount}
          phx-value-currency={currency}
          phx-target={@target}
        >
          <%= money %>
        </.button>
      </div>

      <div class="mt-4">
        <label class="mb-0 text-xs text-grey-light">Enter an amount</label>
        <.live_component
          id="amount_input-keypad"
          module={MoneyInput}
          f={@f}
          min={set_min(@disable_till_amount, @amounts)}
          max={1_000_000}
          field={:input_amount}
          value={@selected_amount}
          timezone={@timezone}
          locale={@locale}
        />
      </div>
    </div>
    """
  end

  @spec set_min(Money.t() | nil, [Money.t()]) :: Decimal.t()
  defp set_min(nil, amounts), do: Enum.at(amounts, 0).amount
  defp set_min(%Money{} = disable_till_amount, _amounts), do: disable_till_amount.amount

  @spec show_selected_text(Money.t(), Money.t()) :: String.t() | nil
  defp show_selected_text(amount, selected_amount) do
    if Money.equal?(amount, selected_amount),
      do: "text-primary border border-1 !border-primary"
  end

  @spec disable_amount?(Money.t() | nil, Money.t()) :: boolean()
  def disable_amount?(nil, _amount), do: false

  def disable_amount?(disabled_till, amount),
    do: Money.compare(disabled_till, amount) in [:eq, :gt]
end
