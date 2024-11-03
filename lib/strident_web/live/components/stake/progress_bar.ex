defmodule StridentWeb.Components.Stake.ProgressBar do
  @moduledoc """
  A simple progress bar using colors to show stake progress,
  as well as personal holdings in the stake.

  Use it like this:
  ```
      <.live_component
        module={StridentWeb.Components.Stake.ProgressBar}
        backed_total={@stake.backed_total}
        buy_in_amount={@tournament.buy_in_amount}
      />
  ```
  """
  use StridentWeb, :live_component
  alias Strident.Explanations

  @defaults %{
    show_percentage: true,
    height: "2.5"
  }
  @stake_progress_explanation Explanations.stake_progress()

  @impl true
  def mount(socket) do
    socket
    |> assign(:stake_progress_explanation, @stake_progress_explanation)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    %{backed_total: %Money{} = backed_total, buy_in_amount: %Money{} = buy_in_amount} = assigns
    backed_total_percent = percent_integer(backed_total, buy_in_amount)

    new_stake =
      case assigns[:new_stake] do
        nil ->
          Money.new(buy_in_amount.currency, 0)

        new_stake ->
          if new_stake |> Money.add!(backed_total) |> Money.compare!(buy_in_amount) == :gt do
            Money.new(buy_in_amount.currency, 0)
          else
            new_stake
          end
      end

    new_stake_percent =
      if Decimal.gt?(buy_in_amount.amount, 0) do
        percent_integer(new_stake, buy_in_amount)
      else
        0
      end

    socket
    |> assign(:backed_total_percent, backed_total_percent)
    |> assign(:new_stake_percent, new_stake_percent)
    |> assign(Map.merge(@defaults, assigns))
    |> then(&{:ok, &1})
  end

  @spec percent_integer(Money.t(), Money.t()) :: integer()
  defp percent_integer(_money, _buy_in_amount) do
    # money
    # |> Stakes.stake_progress(buy_in_amount)
    # |> DecimalUtils.rounded_percent()
    0
  end
end
