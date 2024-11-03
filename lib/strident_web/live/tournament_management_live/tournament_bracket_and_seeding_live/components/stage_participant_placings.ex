defmodule StridentWeb.Components.StageParticipantPlacings do
  @moduledoc """
  Component for resolving StageParticipant ties when Stage `:requires_tiebreaking`
  """
  use StridentWeb, :live_component

  alias Strident.TournamentParticipants
  alias Strident.Tournaments

  @impl true
  def mount(socket) do
    socket
    |> close_confirmation()
    |> then(&{:ok, &1})
  end

  @impl true
  def update(
        %{
          can_manage_tournament: can_manage_tournament,
          tournament: tournament,
          stage: stage
        } = assigns,
        socket
      ) do
    tournament = Tournaments.get_tournament!(tournament.id)

    participant_details_by_id =
      Enum.reduce(tournament.participants, %{}, fn tp, acc ->
        Map.put(acc, tp.id, %{
          logo_url: TournamentParticipants.participant_logo_url(tp),
          name: TournamentParticipants.participant_name(tp, show_email: can_manage_tournament),
          individual: TournamentParticipants.get_user_if_participant_is_individual(tp)
        })
      end)

    socket
    |> assign(can_manage_tournament: can_manage_tournament)
    |> assign(participant_details_by_id: participant_details_by_id)
    |> assign(prize_pool: tournament.prize_pool)
    |> assign(stage_participants: stage.participants)
    |> assign(stage_id: stage.id)
    |> assign(stage_type: stage.type)
    |> assign(stage_status: stage.status)
    |> assign(tournament: tournament)
    |> copy_parent_assigns(assigns)
    |> then(&{:ok, &1})
  end

  defp get_prize(tournament, rank) do
    if tournament.prize_strategy == :prize_pool do
      Map.get(tournament.prize_pool, rank)
    else
      Map.get(tournament.distribution_prize_pool, rank)
    end
  end
end
