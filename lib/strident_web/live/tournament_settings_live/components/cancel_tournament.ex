defmodule StridentWeb.TournamentSettingsLive.Components.CancelTournament do
  @moduledoc false
  require Logger
  use StridentWeb, :live_component
  alias Strident.BracketsStructures
  alias Strident.MatchesGeneration
  alias Strident.Tournaments

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{tournament: tournament} = assigns, socket) do
    stage_types =
      tournament.stages
      |> Enum.sort_by(& &1.round)
      |> Enum.map(& &1.type)

    stage_types_index =
      Enum.find_index(BracketsStructures.valid_stage_type_permutations(), &(&1 == stage_types))

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:stage_types_form, to_form(%{"stage_types" => stage_types_index}))
    |> assign(:tournament, tournament)
    |> assign(:cancel_tournament_concession, false)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("cancel-tournament-concession", %{"cancel_tournament_form" => params}, socket) do
    concession =
      case params do
        %{"concession" => "true"} -> true
        %{"concession" => "false"} -> false
      end

    socket
    |> assign(:cancel_tournament_concession, concession)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("cancel-tournament", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    with true <- tournament.created_by_user_id == current_user.id,
         {:ok, _tournament} <- Tournaments.cancel_tournament(tournament) do
      socket
      |> put_flash(:info, "Tournament was canceled")
      |> push_navigate(
        to: Routes.live_path(socket, StridentWeb.TournamentDashboardLive, tournament.slug)
      )
    else
      false ->
        socket
        |> put_flash(:error, "You cannot cancel the tournament. Only the creator has this power.")
        |> push_patch(
          to: Routes.live_path(socket, StridentWeb.TournamentSettingsLive, tournament.slug)
        )

      {:error, error} ->
        Logger.info("Error while cancelling tournament. #{inspect(error)}", %{
          tournament_id: tournament.id,
          user_id: current_user.id
        })

        Logger.error("Error while cancelling tournament", %{
          tournament_id: tournament.id,
          user_id: current_user.id
        })

        socket
        |> put_flash(:error, "Error while cancelling tournament")
        |> push_patch(
          to: Routes.live_path(socket, StridentWeb.TournamentSettingsLive, tournament.slug)
        )
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change-stage-types", params, socket) do
    %{"stage_types" => int_string} = params
    stage_types_index = String.to_integer(int_string)

    new_stage_types =
      Enum.at(BracketsStructures.valid_stage_type_permutations(), stage_types_index)

    %{tournament: tournament} = socket.assigns

    socket
    |> then(fn socket ->
      case MatchesGeneration.regenerate_tournament(tournament, new_stage_types: new_stage_types) do
        {:ok, _, _} -> put_flash(socket, :info, "Regenerated tournament with new stage types")
        {:error, error} -> put_string_or_changeset_error_in_flash(socket, error)
      end
    end)
    |> then(&{:noreply, &1})
  end
end
