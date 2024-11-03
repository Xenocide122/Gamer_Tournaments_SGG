defmodule StridentWeb.PrizeLogicLive.Index do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.PrizeLogic

  @debounce "20"
  @default_values %{
    "number_of_participants" => 32,
    "buy_in_amount" => Money.new(:USD, 250),
    "required_min_split" => Decimal.new("0.8"),
    "prize_reducer" => Decimal.new("0.9")
  }

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(%{
      page_title: "Prize Logic",
      debounce: @debounce,
      changeset: PrizeLogic.Form.changeset(%PrizeLogic.Form{}, @default_values)
    })
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("change", %{"form" => params}, socket) do
    socket
    |> assign(:changeset, PrizeLogic.Form.changeset(%PrizeLogic.Form{}, params))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("submit", _params, socket) do
    socket
    |> put_flash(:info, "nothing happens...")
    |> then(&{:noreply, &1})
  end
end
