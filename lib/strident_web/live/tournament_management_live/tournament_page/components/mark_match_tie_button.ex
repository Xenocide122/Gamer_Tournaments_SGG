defmodule StridentWeb.TournamentPageLive.Components.MarkMatchTieButton do
  @moduledoc """
  A simple button component that triggers marking MatchParticipants as tied.
  """
  use StridentWeb, :live_component
  alias Strident.Matches.Match
  alias Strident.Winners

  @impl true
  def mount(socket) do
    socket
    |> close_confirmation()
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{match: %Match{} = match} = assigns, socket) do
    is_connected = connected?(socket)

    socket
    |> assign(:is_connected, is_connected)
    |> copy_parent_assigns(assigns)
    |> assign(%{match: match})
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("mark-tie-clicked", _unsigned_params, socket) do
    confirmation_message = mark_match_tie_confirmation_message()

    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "mark-tie",
      confirmation_message: confirmation_message
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("mark-tie", _unsigned_params, socket) do
    socket
    |> mark_tie()
    |> then(&{:noreply, &1})
  end

  defp mark_tie(%{assigns: %{match: %{participants: match_participants}}} = socket) do
    Winners.mark_match_winners(match_participants, self())

    receive do
      {:ok, {:match_winner, _details}} ->
        socket

      {:error, {:match_winner, error}} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
  end

  defp mark_match_tie_confirmation_message do
    assigns = %{}

    ~H"""
    <div>
      <div class="mb-10 text-2xl text-center">
        Are you sure you want to mark this match as a tie?
      </div>
    </div>
    """
  end
end
