defmodule StridentWeb.TournamentPageLive.Components.MarkMatchWinnerButton do
  @moduledoc """
  A simple button component that triggers marking a MatchParticipant as winner.
  """
  use StridentWeb, :live_component
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.Winners
  alias StridentWeb.TournamentPageLive.Components.MarkMatchWinnerConfirmationMessage

  @impl true
  def mount(socket) do
    socket
    |> close_confirmation()
    |> then(&{:ok, &1})
  end

  @impl true
  def update(
        %{
          match_participant: %MatchParticipant{} = match_participant,
          participant_name: participant_name,
          scores_and_names: scores_and_names,
          tournament_id: tournament_id
        } = assigns,
        socket
      ) do
    confirmation_message =
      MarkMatchWinnerConfirmationMessage.mark_match_winner_confirmation_message(%{
        winner_name: participant_name,
        scores: scores_and_names
      })

    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      tournament_id: tournament_id,
      match_participant: match_participant,
      confirmation_message: confirmation_message
    })
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("mark-winner-clicked", _unsigned_params, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "mark-winner",
      confirmation_confirm_values: %{"id" => socket.assigns.match_participant.id}
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("mark-winner", _unsigned_params, socket) do
    socket
    |> mark_winner()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  defp mark_winner(%{assigns: %{match_participant: match_participant}} = socket) do
    Winners.mark_match_winner(match_participant, self())

    receive do
      {:ok, {:match_winner, details}} ->
        %{match_id: match_id, updated_winners: [updated_winner | _]} = details

        socket
        |> track_segment_event("Marked Match Winner", %{
          match_participant_id: updated_winner.id,
          match_id: match_id,
          tournament_id: socket.assigns.tournament_id
        })

      {:error, {:match_winner, error}} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
  end
end
