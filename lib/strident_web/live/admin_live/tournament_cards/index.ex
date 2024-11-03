defmodule StridentWeb.TournamentCardsLive.Index do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Tournaments.TournamentsPageInfoCard
  alias StridentWeb.AdminLive.Components.Menus

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(cards: TournamentsPageInfoCard.admin_list_cards())
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("disable", %{"id" => card_id}, socket) do
    TournamentsPageInfoCard.get_card!(card_id)
    |> update_card(true, socket)
  end

  @impl true
  def handle_event("enable", %{"id" => card_id}, socket) do
    TournamentsPageInfoCard.get_card!(card_id)
    |> update_card(false, socket)
  end

  defp update_card(card, hidden, socket) do
    case TournamentsPageInfoCard.update_card(card, %{hidden: hidden}) do
      {:ok, %{id: new_id} = new_card} ->
        socket
        |> update(
          :cards,
          &Enum.map(&1, fn
            %{id: ^new_id} -> new_card
            c -> c
          end)
        )
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "We are unable to enable this card")
        |> then(&{:noreply, &1})
    end
  end
end
