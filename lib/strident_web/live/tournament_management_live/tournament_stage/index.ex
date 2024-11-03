defmodule StridentWeb.TournamentStage.Index do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias Strident.Matches
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.MatchParticipantSwitching
  alias Strident.NotifyClient
  alias Strident.Stages
  alias Strident.Stages.Stage
  alias Strident.Tournaments
  alias StridentWeb.TournamentManagment.Setup
  alias StridentWeb.TournamentPageLive.AssignTransformer
  alias Phoenix.LiveView.Socket

  on_mount({StridentWeb.InitAssigns, :default})
  on_mount({Setup, :full})

  @impl true
  def mount(_params, _session, socket) do
    %{tournament: tournament} = socket.assigns
    stage_type = filter_current_stage(tournament.stages)

    socket
    |> close_confirmation()
    |> assign(:selected_stage_type, stage_type)
    |> assign(:team_site, :bracket_and_seeding)
    |> assign(:stage, nil)
    |> assign(:form, to_form(%{}, as: :stage_selection))
    |> subscribe_to_tournament_updates()
    |> assign_extra_stage_details()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("do-nothing", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change-stage", params, socket) do
    stage =
      case params do
        %{"stage_selection" => %{"stage" => "round_robin"}} -> :round_robin
        %{"stage_selection" => %{"stage" => "swiss"}} -> :swiss
        %{"stage_selection" => %{"stage" => "double_elimination"}} -> :double_elimination
        %{"stage_selection" => %{"stage" => "single_elimination"}} -> :single_elimination
        %{"stage_selection" => %{"stage" => "battle_royale"}} -> :battle_royale
      end

    socket
    |> assign(:selected_stage_type, stage)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("click-match-participant", _unsigned_params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("resolve-tied-stage-participant", params, socket) do
    %{
      "stage-participant-id" => sp_id,
      "stage_participant" => %{"new_rank" => new_rank}
    } = params

    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    if Tournaments.can_manage_tournament?(current_user, tournament) do
      {new_rank_integer, ""} = Integer.parse(new_rank)
      sp = Stages.get_stage_participant_with_preloads_by(id: sp_id)

      case Stages.manually_resolve_tied_rank(sp, new_rank_integer) do
        {:ok, _updated_sp} ->
          put_flash(socket, :info, "Participant rank updated!")

        {:error, %Ecto.Changeset{} = changeset} ->
          put_humanized_changeset_errors_in_flash(socket, changeset)

        {:error, error} when is_binary(error) ->
          put_flash(socket, :error, error)
      end
    else
      berate_javascript_hacker_kid(socket)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("manually-finish-stage-clicked", %{"stage-id" => stage_id}, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "finish-stage")
    |> assign(:confirmation_confirm_values, %{"stage_id" => stage_id})
    |> assign(:confirmation_message, "Confirm marking stage as finished.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("manually-start-stage-clicked", %{"stage-id" => stage_id}, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "start-stage")
    |> assign(:confirmation_confirm_values, %{"stage_id" => stage_id})
    |> assign(:confirmation_message, "Confirm you want to start this stage.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("finish-stage", %{"stage_id" => stage_id}, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    if Tournaments.can_manage_tournament?(current_user, tournament) do
      case tournament.stages
           |> Enum.find(&(&1.id == stage_id))
           |> Stages.manually_finish_stage() do
        {:ok, _updated_sp} ->
          socket
          |> put_flash(:info, "Manually completed stage.")
          |> push_navigate(
            to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          put_humanized_changeset_errors_in_flash(socket, changeset)

        {:error, error} when is_binary(error) ->
          put_flash(socket, :error, error)
      end
    else
      berate_javascript_hacker_kid(socket)
    end
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true

  def handle_event("start-stage", %{"stage_id" => stage_id}, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    if Tournaments.can_manage_tournament?(current_user, tournament) do
      case tournament.stages
           |> Enum.find(&(&1.id == stage_id))
           |> Stages.update_stage(%{status: :in_progress}) do
        {:ok, _updated_sp} ->
          socket
          |> put_flash(:info, "Stage has started.")
          |> push_navigate(
            to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          put_humanized_changeset_errors_in_flash(socket, changeset)
      end
    else
      berate_javascript_hacker_kid(socket)
    end
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("finish-tournament-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "finish-tournament")
    |> assign(:confirmation_message, "Confirm marking tournament as finished.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("finish-tournament", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    if Tournaments.can_manage_tournament?(current_user, tournament) do
      socket
      |> update_tournament_status(:finished)
      |> close_confirmation()
    else
      berate_javascript_hacker_kid(socket)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("cancel-tournament-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "cancel-tournament")
    |> assign(:confirmation_message, "Confirm cancelling tournament.")
    |> assign(:confirmation_confirm_prompt, "Cancel it")
    |> assign(:confirmation_cancel_prompt, "Don't cancel it")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("cancel-tournament", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    if Tournaments.can_manage_tournament?(current_user, tournament) do
      socket
      |> update_tournament_status(:cancelled)
      |> close_confirmation()
    else
      berate_javascript_hacker_kid(socket)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("update-tournament-status", %{"tournament" => %{"status" => status}}, socket) do
    if Tournaments.can_manage_tournament?(socket.assigns.current_user, socket.assigns.tournament) do
      update_tournament_status(socket, status)
    else
      berate_javascript_hacker_kid(socket)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "switch-match-participant",
        %{
          "match-id" => match_id,
          "mp-id" => mp_id,
          "switch_match_participant" => %{"new_tp_id" => new_tp_id}
        },
        socket
      ) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    if Tournaments.can_manage_tournament?(current_user, tournament) do
      mp_id = if mp_id in ["null", ""], do: nil, else: mp_id
      new_tp_id = if new_tp_id in ["null", ""], do: nil, else: new_tp_id

      socket
      |> switch_first_round_match_participant(match_id, mp_id, new_tp_id)
    else
      berate_javascript_hacker_kid(socket)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_winner, details}, socket) do
    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_match_winner(tournament, details)
    end)
    |> then(fn socket ->
      %{assigns: %{tournament: tournament}} = socket

      if are_all_matches_finished_but_stage_isnt?(tournament) do
        push_navigate(socket,
          to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
        )
      else
        socket
      end
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_participant_created, details}, socket) do
    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_created_match_participant(
        tournament,
        details
      )
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_participant_deleted, details}, socket) do
    mp = details.match_participant

    updated_mps =
      details.match_participant.match.participants
      |> Enum.reject(&(&1.id == mp.id))

    is_resettable =
      Enum.any?(updated_mps, &(&1.rank == 0)) and
        not Enum.any?(mp.match.children, fn %{participants: child_mps} ->
          Enum.any?(child_mps, &(&1.rank == 0))
        end)

    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_deleted_match_participant(
        tournament,
        details
      )
    end)
    |> push_event("update_node", %{
      stage_id: mp.match.stage_id,
      match_id: mp.match_id,
      match_type: mp.match.type,
      stage_round: mp.match.stage.round,
      match_round: mp.match.round,
      starts_at: mp.match.starts_at,
      is_resettable: is_resettable,
      tournament_status: socket.assigns.tournament.status
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_participant_updated, details}, socket) do
    %{id: mp_id} = mp = details.match_participant

    updated_mps =
      details.match_participant.match.participants
      |> Enum.map(fn
        %{id: ^mp_id} -> mp
        other_mp -> other_mp
      end)

    is_resettable =
      Enum.any?(updated_mps, &(&1.rank == 0)) and
        not Enum.any?(mp.match.children, fn %{participants: child_mps} ->
          Enum.any?(child_mps, &(&1.rank == 0))
        end)

    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_updated_match_participant(
        tournament,
        details
      )
    end)
    |> push_event("update_node", %{
      stage_id: mp.match.stage_id,
      match_id: mp.match_id,
      match_type: mp.match.type,
      stage_round: mp.match.stage.round,
      match_round: mp.match.round,
      starts_at: mp.match.starts_at,
      is_resettable: is_resettable,
      tournament_status: socket.assigns.tournament.status,
      skip_rebuilding_node_if_can_manage_tournament: true
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:tournament_matches_regenerated, details}, socket) do
    %{tournament_id: tournament_id} = details
    %{tournament: tournament} = socket.assigns

    if tournament.id == tournament_id do
      {:cont, socket} =
        Setup.do_on_mount(socket, tournament.slug, Setup.tournament_full_preloads())

      put_flash(socket, :info, "Tournament regenerated, syncing view...")
    else
      socket
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp are_all_matches_finished_but_stage_isnt?(tournament) do
    %{stages: stages} = tournament

    all_matches_finished? = fn stage ->
      Enum.all?(stage.matches, &Matches.is_match_finished?/1)
    end

    Enum.reduce_while(stages, false, fn stage, _false ->
      if stage.status != :finished and all_matches_finished?.(stage) do
        {:halt, true}
      else
        {:cont, false}
      end
    end)
  end

  defp subscribe_to_tournament_updates(%{assigns: %{tournament: tournament}} = socket) do
    tap(socket, fn _ ->
      if connected?(socket) do
        NotifyClient.subscribe_to_events_affecting(tournament)
      end
    end)
  end

  defp switch_first_round_match_participant(socket, match_id, mp_id, new_tp_id) do
    if Tournaments.can_manage_tournament?(socket.assigns.current_user, socket.assigns.tournament) do
      case MatchParticipantSwitching.switch_first_round_match_participant(
             mp_id,
             match_id,
             new_tp_id
           ) do
        {:ok, results} ->
          socket
          |> maybe_push_created_mp(results)
          |> maybe_push_updated_other_mp(results)
          |> maybe_push_deleted_mp(results)
          |> put_flash(:info, "Match participants switched!")

        {:error, _, particular_error, _} = error ->
          Logger.error("Error switching match participants. #{inspect(error, pretty: true)}")

          error_message =
            if is_binary(particular_error) do
              particular_error
            else
              "Could not switch participants. Please reload the page and try again."
            end

          put_flash(socket, :error, error_message)
      end
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @spec maybe_push_created_mp(Socket.t(), map()) :: Socket.t()
  defp maybe_push_created_mp(socket, results) do
    if mp = Map.get(results, :created_mp) do
      push_created_mp(socket, mp)
    else
      socket
    end
  end

  @spec push_created_mp(Socket.t(), MatchParticipant.t()) :: Socket.t()
  defp push_created_mp(socket, mp) do
    if mp.match.type in [:upper, :lower, :standard] do
      push_event(socket, "created_match_participant", %{
        mp_id: mp.id,
        tp_id: mp.tournament_participant_id,
        match_id: mp.match.id,
        group: mp.match.group,
        match_type: mp.match.type
      })
    else
      socket
    end
  end

  @spec maybe_push_updated_other_mp(Socket.t(), map()) :: Socket.t()
  defp maybe_push_updated_other_mp(socket, results) do
    if mp = Map.get(results, :updated_other_mp) do
      push_updated_other_mp(socket, mp)
    else
      socket
    end
  end

  @spec push_updated_other_mp(Socket.t(), MatchParticipant.t()) :: Socket.t()
  defp push_updated_other_mp(socket, mp) do
    if mp.match.type in [:upper, :lower, :standard] do
      push_event(socket, "updated_other_match_participant", %{
        mp_id: mp.id,
        tp_id: mp.tournament_participant_id,
        match_id: mp.match.id,
        group: mp.match.group,
        match_type: mp.match.type
      })
    else
      socket
    end
  end

  @spec maybe_push_deleted_mp(Socket.t(), map()) :: Socket.t()
  defp maybe_push_deleted_mp(socket, results) do
    if mp = Map.get(results, :deleted_mp) do
      push_deleted_mp(socket, mp)
    else
      socket
    end
  end

  @spec push_deleted_mp(Socket.t(), MatchParticipant.t()) :: Socket.t()
  defp push_deleted_mp(socket, mp) do
    cond do
      mp.match.type in [:upper, :lower, :standard] ->
        push_event(socket, "deleted_match_participant", %{
          mp_id: mp.id,
          match_id: mp.match.id,
          group: mp.match.group,
          match_type: mp.match.type
        })

      mp.match.type in [:pool, :swiss] ->
        push_event(socket, "reset_null_switcher_value", %{group: mp.match.group, mp_id: mp.id})

      true ->
        socket
    end
  end

  defp update_tournament_status(socket, status) do
    %{assigns: %{tournament: tournament}} = socket

    case Tournaments.update_tournament_status(tournament, status) do
      {:ok, %{status: new_status}} ->
        socket
        |> update(:tournament, &%{&1 | status: new_status})
        |> put_flash(:info, "Changed tournament status to #{new_status}")

      {:error, %Ecto.Changeset{} = changeset} ->
        put_humanized_changeset_errors_in_flash(socket, changeset)

      {:error, error} when is_binary(error) ->
        put_flash(socket, :error, error)
    end
  end

  @spec assign_extra_stage_details(Socket.t()) :: Socket.t()
  defp assign_extra_stage_details(socket) do
    {extra_stage_details, _last_stage} =
      socket.assigns.tournament.stages
      |> Enum.sort_by(& &1.round)
      |> Enum.reduce({%{}, nil}, fn stage, {extra_stage_details, previous_stage} ->
        previous_stage_status =
          case previous_stage do
            nil -> nil
            %Stage{} = previous_stage -> previous_stage.status
          end

        extra_stage_details
        |> Map.put(stage.id, %{previous_stage_status: previous_stage_status})
        |> then(&{&1, stage})
      end)

    assign(socket, :extra_stage_details, extra_stage_details)
  end

  defp get_stages_from_links([]), do: []

  defp get_stages_from_links(stages) do
    stages
    |> Enum.sort_by(& &1.round)
    |> Enum.map(&{humanize(Map.get(&1, :type)), Map.get(&1, :type)})
    |> Enum.uniq()
  end

  defp filter_current_stage([]), do: nil

  defp filter_current_stage(stages) do
    case Enum.sort_by(stages, & &1.round) do
      [] -> nil
      [%{status: :finished}, stage] -> stage.type
      [stage | _] -> stage.type
    end
  end
end
