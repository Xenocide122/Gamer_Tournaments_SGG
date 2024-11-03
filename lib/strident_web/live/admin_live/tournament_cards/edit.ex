defmodule StridentWeb.TournamentCardsLive.Edit do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Tournaments.TournamentsPageInfoCard

  def mount(%{"id" => id}, _session, socket) do
    card = TournamentsPageInfoCard.get_card!(id)

    socket
    |> assign(changeset: TournamentsPageInfoCard.changeset(card))
    |> assign(card: card)
    |> then(&{:ok, &1})
  end
end
