defmodule StridentWeb.TournamentPageLive.Components.PoolStageMatches do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{
          matches: matches,
          group: group,
          stage_id: stage_id,
          stage_type: stage_type,
          stage_status: stage_status,
          participant_details: participant_details,
          can_manage_tournament: can_manage_tournament,
          tournament_id: tournament_id
        } = assigns,
        socket
      ) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      matches: matches,
      group: group,
      stage_id: stage_id,
      stage_type: stage_type,
      stage_status: stage_status,
      participant_details: participant_details,
      can_manage_tournament: can_manage_tournament,
      tournament_id: tournament_id
    })
    |> then(&{:ok, &1})
  end
end
