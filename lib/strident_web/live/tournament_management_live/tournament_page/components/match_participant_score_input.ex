defmodule StridentWeb.TournamentPageLive.Components.MatchParticipantScoreInput do
  @moduledoc """
  A simple text input component that triggers updating a MatchParticipant's score.
  """
  use StridentWeb, :live_component
  alias Strident.MatchParticipants
  alias Strident.MatchParticipants.MatchParticipant

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{match_participant: %MatchParticipant{} = match_participant} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:match_participant, match_participant)
    |> assign(:form, to_form(%{}, as: :match_participant))
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "update-score",
        %{"match_participant" => %{"score" => score}},
        %{assigns: %{match_participant: match_participant}} = socket
      ) do
    case MatchParticipants.update_match_participant(match_participant, %{score: score}) do
      {:ok, %{score: _new_score}} ->
        socket
        |> track_segment_event("Set Match Participant Score", %{
          match_participant_id: match_participant.id,
          match_id: match_participant.match_id,
          score: score
        })
        |> then(&{:noreply, &1})

      {:error, error} ->
        socket
        |> put_string_or_changeset_error_in_flash(error)
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "Unable to update score. Please reload the page and try again.")
        |> then(&{:noreply, &1})
    end
  end
end
