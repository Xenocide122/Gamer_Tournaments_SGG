defmodule StridentWeb.PartyManagementLive.Show do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Parties
  alias Strident.Prizes
  alias Strident.Tournaments
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:validation_msg, nil)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(
        %{"tournament" => tournament_id, "id" => party_id, "participant" => participant_id},
        _url,
        socket
      ) do
    tournament = Tournaments.get_tournament!(tournament_id)
    participant = Tournaments.get_tournament_participant_with_preloads!(participant_id, [])

    socket
    |> assign_party_and_can_manage_ids(party_id)
    |> assign(tournament: tournament)
    |> assign(participant: participant)
    |> assign(prize_pool: prize_for_rank(tournament, participant.rank))
    |> then(&{:noreply, &1})
  end

  defp assign_party_and_can_manage_ids(socket, party_id) do
    party =
      Parties.get_party_with_preloads!(party_id, [
        :party_invitations,
        party_members: [user: []]
      ])

    can_manage_ids =
      party.party_members
      |> Enum.filter(&(&1.type in [:manager, :captain]))
      |> Enum.map(& &1.user_id)

    socket
    |> assign(party: party)
    |> assign(can_manage_ids: can_manage_ids)
  end

  defp prize_for_rank(%{prize_strategy: :prize_distribution} = tournament, rank) do
    Map.get(tournament.distribution_prize_pool, rank)
  end

  defp prize_for_rank(%{prize_strategy: :prize_pool} = tournament, rank) do
    Map.get(tournament.prize_pool, rank)
  end
end
