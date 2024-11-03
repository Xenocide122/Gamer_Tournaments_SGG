defmodule StridentWeb.TournamentPageLive.Components.NextUpcomingMatch do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Extension.NaiveDateTime
  alias Strident.MatchParticipants
  alias Strident.NotifyClient
  alias Strident.TournamentParticipants

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{captained_participant_ids: captained_participant_ids, tournament: tournament} = assigns,
        socket
      ) do
    next_match = next_match(tournament)

    if connected?(socket) and next_match,
      do: Enum.each(next_match.participants, &NotifyClient.subscribe_to_events_affecting/1)

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:tournament, tournament)
    |> assign(:match, next_match)
    |> assign(:captained_participant_ids, captained_participant_ids)
    |> assign(:participants, tournament.participants)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "mark-ready",
        %{"match_participant_id" => id},
        %{assigns: %{match: %{participants: match_participants}}} = socket
      ) do
    change_match_participant_readiness(match_participants, id, true)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "mark-not-ready",
        %{"match_participant_id" => id},
        %{assigns: %{match: %{participants: match_participants}}} = socket
      ) do
    change_match_participant_readiness(match_participants, id, false)
    {:noreply, socket}
  end

  defp change_match_participant_readiness(match_participants, id, is_ready) do
    match_participants
    |> Enum.find(&(&1.id == id))
    |> MatchParticipants.change_match_participant_readiness(is_ready)
  end

  defp next_match(%{stages: stages}) do
    stages
    |> Enum.flat_map(& &1.matches)
    |> Enum.filter(fn
      %{participants: []} -> false
      %{participants: match_participants} -> Enum.all?(match_participants, &is_nil(&1.rank))
    end)
    |> Enum.sort_by(& &1.starts_at, fn
      nil, _ -> false
      _, nil -> true
      time_1, time_2 -> NaiveDateTime.compare(time_1, time_2) == :lt
    end)
    |> List.first()
  end
end
