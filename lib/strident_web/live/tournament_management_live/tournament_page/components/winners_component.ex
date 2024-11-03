defmodule StridentWeb.TournamentPageLive.Components.WinnersComponent do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.TournamentParticipants

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :winners, [])}
  end

  @impl true
  def update(%{tournament: tournament}, socket) do
    winners =
      tournament.participants
      |> Enum.reduce([], fn %{rank: rank} = participant, winners ->
        # we need to cast since keys in enum postgres are strings
        if rank in Map.keys(tournament.prize_pool) do
          [participant | winners]
        else
          winners
        end
      end)
      |> Enum.sort_by(& &1.rank)

    {:ok, assign(socket, :winners, winners)}
  end

  def card_color(rank) when is_integer(rank) do
    case rank do
      0 -> "bg-primary"
      1 -> "bg-brands-discord"
      2 -> "bg-secondary"
      _ -> ""
    end
  end
end
