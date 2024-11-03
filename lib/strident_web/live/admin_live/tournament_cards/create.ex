defmodule StridentWeb.TournamentCardsLive.Create do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Tournaments.TournamentsPageInfoCard

  def mount(_params, _session, socket) do
    socket
    |> assign(changeset: TournamentsPageInfoCard.changeset(%TournamentsPageInfoCard{}))
    |> then(&{:ok, &1})
  end
end
