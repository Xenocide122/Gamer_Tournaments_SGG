defmodule StridentWeb.Common.MoneyInput do
  @moduledoc """
  Helpers to render inputs for money with currency

  Much of this code was directly copied from
  https://github.com/kipcole9/money/issues/111

  For the foreseeable future, Strident will only support USD
  but it's good to afford future extension.
  """
  use StridentWeb, :live_component
  alias Strident.MoneyUtils
  alias Phoenix.LiveView.JS

  @enforce_keys [:field]
  defstruct [:f, :field]

  # step could be different for currencies other than, e.g. USD, EUR
  @step 1.00

  @currency_options MoneyUtils.allowed_currencies()
                    |> Stream.map(&Money.Currency.currency_for_code/1)
                    |> Stream.map(&elem(&1, 1))
                    |> Enum.map(fn %{code: code, name: _name, symbol: symbol} ->
                      {symbol, code}
                    end)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="hidden" phx-mounted={JS.show()} phx-disconnected={JS.hide()} phx-connected={JS.show()}>
      <div class={["flex", @class]}>
        <%= money_with_currency_input(@f, @field, @opts) %>
      </div>

      <%= if Keyword.get(@opts, :show_error_tag) do %>
        <%= error_tag(@f, @field) %>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{f: f, field: field} = assigns, socket) do
    class = Map.get(assigns, :class, "")
    class = "money-input #{class}"

    opts =
      assigns
      |> Map.drop([:f, :field])
      |> Map.to_list()

    socket
    |> assign(%{
      f: f,
      field: field,
      class: class,
      opts: opts
    })
    |> then(&{:ok, &1})
  end

  def money_with_currency_input(form, field, opts \\ []) do
    form
    |> money_with_currency_builder(field, opts)
    |> then(&html_escape([&1.(:currency), &1.(:amount)]))
  end

  defp money_with_currency_builder(form, field, opts) do
    {id, opts} = Keyword.pop(opts, :id, input_id(form, field))
    {name, opts} = Keyword.pop(opts, :name, input_name(form, field))

    money_value =
      case input_value(form, field) do
        %Money{} = money -> money
        _ -> Keyword.get(opts, :value)
      end

    %{amount: amount, currency: currency} = safe_money_map(money_value)

    fn
      :amount ->
        {class, opts} =
          opts
          |> Keyword.drop([:class])
          |> Keyword.pop(:number_input_class, "")

        class = "money-amount__input rounded-l-none rounded-r #{class}"
        opts = money_with_currency_options(:amount, id, name, opts, amount, opts)

        number_input(
          :money_with_currency,
          :amount,
          Keyword.merge([step: @step, class: class], opts)
        )

      :currency ->
        {class, opts} =
          opts
          |> Keyword.drop([:class])
          |> Keyword.pop(:currency_select_class, "")

        class = "w-1/5 rounded-l rounded-r-none bg-grey-light #{class}"

        opts = money_with_currency_options(:currency, id, name, opts, currency, opts)

        select(
          :money_with_currency,
          :currency,
          @currency_options,
          Keyword.merge([class: class], opts)
        )
    end
  end

  defp money_with_currency_options(type, id, name, opts, amount_or_currency, opts) do
    suff = Atom.to_string(type)

    opts
    |> Keyword.put_new(:id, to_string(id) <> "_" <> suff)
    |> Keyword.put_new(:name, name <> "[" <> suff <> "]")
    |> Keyword.put(:value, amount_or_currency)
  end

  defp safe_money_map(nil), do: %{amount: "", currency: :USD}
  defp safe_money_map({:error, _}), do: %{amount: Decimal.new(0), currency: :USD}

  defp safe_money_map(%{amount: amount, currency: currency}),
    do: %{amount: amount, currency: currency}
end
