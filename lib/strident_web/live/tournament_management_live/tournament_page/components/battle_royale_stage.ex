defmodule StridentWeb.TournamentPageLive.Components.BattleRoyaleStage do
  @moduledoc """
  Displays comrehensive info on a "battle_royale" type stage,
  e.g. Round Robin.

  If current user has the necessary permission
  (ATOW - if they are "staff", i.e. `is_staff == true`)
  then they can update scores and mark winners.
  """
  use StridentWeb, :live_component
  require Logger
  alias Strident.BattleRoyale
  alias Strident.Matches.Match
  alias Strident.MatchParticipants
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.Stages.Stage
  alias Strident.Tournaments
  alias Strident.Tournaments.TournamentParticipant
  alias StridentWeb.TournamentParticipants.TournamentParticipantsHelpers
  alias Phoenix.LiveView.Socket

  @type per_participant_results :: %{
          :sp_id => nil | Strident.id(),
          :placing => nil | non_neg_integer(),
          :advance => nil | :upper | :lower
        }
  @type participant_results :: %{TournamentParticipant.id() => per_participant_results()}
  @type displayed_round_by_group :: %{binary() => nil | Match.round()}

  @impl true
  def mount(socket) do
    socket
    |> assign(:sort_by_stat_label, nil)
    |> assign(:sort_by_stat_direction, :desc)
    |> assign(:show_unassigned_stage_participants_for_group, nil)
    |> assign(:form_switch_match_participant, to_form(%{}, as: :switch_match_participant))
    |> assign(:form_stage_participant, to_form(%{}, as: :stage_participant))
    |> assign(:form_select_to_advance, to_form(%{}, as: :select_to_advance))
    |> assign(:selected_participant_id_for_switching, nil)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    %{
      stage: stage,
      participants: participants,
      tournament_status: tournament_status,
      tournament: tournament,
      current_user: current_user
    } = assigns

    stat_labels = tournament.stat_labels || []
    stages_count = Enum.count(tournament.stages)
    stage_has_child = stage.round < stages_count - 1

    socket
    |> copy_parent_assigns(assigns)
    |> close_confirmation()
    |> assign(
      :can_manage_tournament,
      Tournaments.can_manage_tournament?(current_user, tournament)
    )
    |> assign(:tournament_id, stage.tournament_id)
    |> assign(:tournament_status, tournament_status)
    |> assign(:tournament_slug, tournament.slug)
    |> assign(:stage_id, stage.id)
    |> assign(:stage_type, stage.type)
    |> assign(:stage_status, stage.status)
    |> assign(:stage_round, stage.round)
    |> assign(:stage_has_child, stage_has_child)
    |> assign(:stat_labels, stat_labels)
    |> assign(:default_stats, MatchParticipants.default_stats(stat_labels))
    |> TournamentParticipantsHelpers.assign_participant_details(participants)
    |> assign_participant_options()
    |> assign_groups(stage)
    |> assign_all_mps_have_stats()
    |> assign(:unsaved_stats_changesets_by_mp_id, %{})
    |> assign_new(:displayed_round_by_group, fn -> %{} end)
    |> assign_new(:selecting_to_advance, fn -> false end)
    |> assign_new(:tp_ids_to_advance, fn -> [] end)
    |> assign_child_stage_type(stage)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("click-displayed-round", params, socket) do
    {group, round} =
      case params do
        %{"group" => group, "round" => nil} -> {group, nil}
        %{"group" => group, "round" => round} -> {group, String.to_integer(round)}
        %{"group" => group} -> {group, nil}
      end

    socket
    |> update(:displayed_round_by_group, fn
      nil ->
        %{group => round}

      displayed_round_by_group when is_map(displayed_round_by_group) ->
        Map.put(displayed_round_by_group, group, round)
    end)
    |> then(&{:noreply, &1})
  end

  def handle_event("update-mp-stats", params, socket) do
    %{
      "match_participant" => %{
        "group" => group,
        "round" => round_string,
        "tp_id" => tp_id,
        "stat_label" => stat_label,
        "stats" => stats
      }
    } = params

    round = String.to_integer(round_string)

    [value] = Map.values(stats)

    %{stats_changesets_by_round: %{^round => stats_changeset}} =
      get_in(socket.assigns.groups, [group, :participant_results, tp_id])

    old_stats = Ecto.Changeset.get_field(stats_changeset, :stats)
    new_stats = Map.put(old_stats, stat_label, value)
    new_stats_changeset = MatchParticipant.stats_changeset(stats_changeset, new_stats)

    new_groups =
      put_in(
        socket.assigns.groups,
        [group, :participant_results, tp_id, :stats_changesets_by_round, round],
        new_stats_changeset
      )

    socket
    |> assign(:groups, new_groups)
    |> then(fn socket ->
      mp_id = Ecto.Changeset.get_field(new_stats_changeset, :id)

      new_unsaved_stats_changesets_by_mp_id =
        if Enum.any?(new_stats_changeset.changes) do
          Map.put(socket.assigns.unsaved_stats_changesets_by_mp_id, mp_id, new_stats_changeset)
        else
          Map.drop(socket.assigns.unsaved_stats_changesets_by_mp_id, [mp_id])
        end

      assign(socket, :unsaved_stats_changesets_by_mp_id, new_unsaved_stats_changesets_by_mp_id)
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("save-stats-changesets", _params, socket) do
    case socket.assigns.unsaved_stats_changesets_by_mp_id
         |> Map.values()
         |> BattleRoyale.save_stats_changesets() do
      {:ok, results} ->
        Logger.info("Saved stats changesets.", logger_metadata(socket))

        socket
        |> assign(:unsaved_stats_changesets_by_mp_id, %{})
        |> assign_all_mps_have_stats()
        |> put_flash(
          :info,
          "successfully updated stats of #{Enum.count(results)} match participants"
        )

      {:error, _, error, _} ->
        socket
        |> log_concise_error_and_verbose_info(error, "Unable to create next round")
        |> put_string_or_changeset_error_in_flash(error)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("create-next-round", _params, socket) do
    %{stage_id: stage_id, tournament_slug: tournament_slug} = socket.assigns

    case BattleRoyale.create_next_round(stage_id) do
      {:ok, _results} ->
        socket
        |> put_flash(:info, "Successfully created next round")
        |> push_navigate(to: ~p"/tournament/#{tournament_slug}/bracket_and_seeding")
        |> then(&{:noreply, &1})

      {:error, _, error, _} ->
        socket
        |> log_concise_error_and_verbose_info(error, "Unable to create next round")
        |> put_string_or_changeset_error_in_flash(error)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("delete-last-round-clicked", _params, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "delete-last-round",
      confirmation_message: "Confirm deleting last round.",
      confirmation_confirm_prompt: "Delete it",
      confirmation_cancel_prompt: "Don't delete it"
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("delete-last-round", _params, socket) do
    case BattleRoyale.delete_last_round(socket.assigns.stage_id) do
      {:ok, _results} ->
        %{tournament_slug: tournament_slug} = socket.assigns

        socket
        |> put_flash(:info, "Successfully deleted last round")
        |> push_redirect(
          to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament_slug)
        )
        |> then(&{:noreply, &1})

      {:error, _, error, _} ->
        socket
        |> log_concise_error_and_verbose_info(error, "Unable to delete last round")
        |> put_string_or_changeset_error_in_flash(error)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("complete-stage-clicked", _params, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "complete-stage",
      confirmation_message: "Confirm completing stage.",
      confirmation_confirm_prompt: "Complete it",
      confirmation_cancel_prompt: "Don't complete it"
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("complete-stage", _params, socket) do
    case BattleRoyale.complete_stage(socket.assigns.stage_id) do
      {:ok, _results} ->
        %{tournament_slug: tournament_slug} = socket.assigns

        socket
        |> put_flash(:info, "Successfully completed stage")
        |> push_redirect(
          to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament_slug)
        )
        |> then(&{:noreply, &1})

      {:error, _, error, _} ->
        socket
        |> log_concise_error_and_verbose_info(error, "Unable to complete stage")
        |> put_string_or_changeset_error_in_flash(error)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("start-selecting-to-advance", _params, socket) do
    {:noreply, assign(socket, :selecting_to_advance, true)}
  end

  @impl true
  def handle_event("select-to-advance-changed", params, socket) do
    %{"select_to_advance" => %{"selected_to_advance" => boolean_string, "tp_id" => tp_id}} =
      params

    case boolean_string do
      "true" ->
        already_advancing = tp_id in socket.assigns.tp_ids_to_advance
        update(socket, :tp_ids_to_advance, &if(already_advancing, do: &1, else: [tp_id | &1]))

      "false" ->
        update(socket, :tp_ids_to_advance, &(&1 -- [tp_id]))
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("move-to-next-stage-clicked", _params, socket) do
    %{stage_round: stage_round} = socket.assigns
    next_stage_number = stage_round + 2

    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "move-to-next-stage",
      confirmation_message:
        "Confirm moving to stage #{next_stage_number} with #{Enum.count(socket.assigns.tp_ids_to_advance)} participants.",
      confirmation_confirm_prompt: "Confirm move",
      confirmation_cancel_prompt: "No, don't move"
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("move-to-next-stage", _params, socket) do
    %{stage_id: stage_id, stage_round: stage_round, tp_ids_to_advance: tp_ids_to_advance} =
      socket.assigns

    next_stage_number = stage_round + 2

    case BattleRoyale.move_to_next_stage(stage_id, tp_ids_to_advance) do
      {:ok, _results} ->
        %{tournament_slug: tournament_slug} = socket.assigns

        socket
        |> put_flash(:info, "Successfully moved to stage #{next_stage_number}")
        |> push_redirect(
          to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament_slug)
        )
        |> then(&{:noreply, &1})

      {:error, _, error, _} ->
        socket
        |> log_concise_error_and_verbose_info(
          error,
          "Unable to move to stage #{next_stage_number}"
        )
        |> put_string_or_changeset_error_in_flash(error)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("fill-in-all-mp-stats", _params, socket) do
    case socket.assigns do
      %{current_user: %{is_staff: true}} ->
        Strident.QaHacks.fill_in_all_mp_stats_in_stage(socket.assigns.stage_id)

        socket
        |> put_flash(:info, "OK hopefully that worked. Refresh the page.")
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> berate_javascript_hacker_kid()
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("sort-by-stat", %{"stat-label" => stat_label}, socket) do
    new_direction =
      if stat_label == socket.assigns.sort_by_stat_label and
           socket.assigns.sort_by_stat_direction == :desc do
        :asc
      else
        :desc
      end

    socket
    |> assign(:sort_by_stat_label, stat_label)
    |> assign(:sort_by_stat_direction, new_direction)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-unassigned-mp-to-group", %{"group" => group}, socket) do
    socket
    |> add_unassigned_mp_to_group(group)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("click-participant-for-switching", params, socket) do
    %{"selected-participant-id-for-switching" => selected_participant_id_for_switching} = params

    socket
    |> assign(:selected_participant_id_for_switching, selected_participant_id_for_switching)
    |> then(&{:noreply, &1})
  end

  def assign_child_stage_type(socket, %{children: []}) do
    assign(socket, :child_stage_type, nil)
  end

  def assign_child_stage_type(socket, %{children: [%{type: type}]}) do
    assign(socket, :child_stage_type, type)
  end

  defp add_unassigned_mp_to_group(socket, group) do
    assign(socket, :show_unassigned_stage_participants_for_group, group)
  end

  defp assign_participant_options(socket) do
    empty_participant_option = {"empty", nil}

    participant_options =
      socket.assigns.participant_details
      |> Enum.map(fn {id, %{name: name}} -> {name, id} end)
      |> Enum.sort_by(&elem(&1, 0))
      |> then(&[empty_participant_option | &1])

    assign(socket, :participant_options, participant_options)
  end

  defp put_placings(participant_results, sps) do
    Enum.reduce(participant_results, participant_results, fn
      {tp_id, _results}, acc ->
        %{id: sp_id, rank: rank} =
          Enum.find(sps, &(&1.tournament_participant_id == tp_id)) || %{id: nil, rank: nil}

        placing = if is_integer(rank), do: rank + 1, else: rank

        Map.update!(acc, tp_id, fn results ->
          results
          |> Map.put(:placing, placing)
          |> Map.put(:sp_id, sp_id)
        end)
    end)
  end

  @spec assign_groups(Socket.t(), Stage.t()) :: Socket.t()
  defp assign_groups(socket, stage) do
    groups =
      stage.matches
      |> Enum.group_by(& &1.group)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.reduce(%{}, fn {group, same_group_matches}, groups ->
        participant_results =
          same_group_matches
          |> build_participant_results(socket.assigns.default_stats)
          |> put_placings(stage.participants)
          |> put_advance_to_next_stage(stage)

        first_round_match_id =
          participant_results
          |> Map.values()
          |> Enum.map(&Map.get(&1, :first_round_match_id))
          |> Enum.uniq()
          |> Enum.sort()
          |> List.first()

        Map.put(groups, group, %{
          first_round_match_id: first_round_match_id,
          matches: same_group_matches,
          participant_results: participant_results
        })
      end)

    assign(socket, :groups, groups)
  end

  defp put_advance_to_next_stage(participants, stage) do
    if Enum.any?(stage.children) and stage.settings != [] do
      advance_settings = transpose_settings(stage)

      participants
      |> Enum.map(fn {participant, values} ->
        # {participant, Map.put(values, :advance, nil)}
        {participant, advance_participant(advance_settings, values)}
      end)
      |> Enum.into(%{})
    else
      participants
      |> Enum.map(fn {participant, values} ->
        {participant, Map.put(values, :advance, nil)}
      end)
      |> Enum.into(%{})
    end
  end

  defp advance_participant(_settings, %{placing: nil} = participant_values),
    do: participant_values

  defp advance_participant(settings, participant_values) do
    %{placing: placing} = participant_values

    case settings do
      %{number_upper_to_advance_per_group: number_upper_to_advance_per_group}
      when placing <= number_upper_to_advance_per_group ->
        Map.put(participant_values, :advance, :upper)

      %{
        number_upper_to_advance_per_group: number_upper_to_advance_per_group,
        number_lower_to_advance_per_group: number_lower_to_advance_per_group
      }
      when placing <= number_lower_to_advance_per_group + number_upper_to_advance_per_group ->
        Map.put(participant_values, :advance, :lower)

      %{number_upper_to_advance: number_upper_to_advance}
      when placing <= number_upper_to_advance ->
        Map.put(participant_values, :advance, :upper)

      %{
        number_upper_to_advance: number_upper_to_advance,
        number_lower_to_advance: number_lower_to_advance
      }
      when placing <= number_lower_to_advance + number_upper_to_advance ->
        Map.put(participant_values, :advance, :lower)

      %{number_to_advance: number_to_advance} when placing <= number_to_advance ->
        Map.put(participant_values, :advance, :upper)

      _ ->
        Map.put(participant_values, :advance, nil)
    end
  end

  @spec assign_all_mps_have_stats(Socket.t()) :: Socket.t()
  defp assign_all_mps_have_stats(socket) do
    assign(socket, :all_mps_have_stats, all_mps_have_stats?(socket))
  end

  defp all_mps_have_stats?(socket) do
    Enum.all?(socket.assigns.groups, fn {_group, %{participant_results: participant_results}} ->
      all_participant_results_not_missing_stats?(participant_results, socket.assigns.stat_labels)
    end)
  end

  defp all_participant_results_not_missing_stats?(participant_results, labels) do
    Enum.all?(participant_results, fn {_tp_id, %{stats_changesets_by_round: changesets}} ->
      all_changesets_not_missing_stats?(changesets, labels)
    end)
  end

  defp all_changesets_not_missing_stats?(changesets, labels) do
    Enum.all?(changesets, fn {_round, changeset} ->
      not MatchParticipants.is_missing_stats?(changeset, labels)
    end)
  end

  defp transpose_settings(stage) do
    Enum.reduce(stage.settings, %{}, fn
      %{name: key} = setting, settings -> Map.put(settings, key, elem(setting.value, 0))
    end)
  end

  @spec build_participant_results([Match.t()], MatchParticipant.stats()) :: participant_results()
  defp build_participant_results(matches, default_stats) do
    for %{participants: mps, round: round} <- matches, mp <- mps, reduce: %{} do
      results ->
        stats = mp.stats || default_stats
        stats_changeset = MatchParticipant.stats_changeset(mp, stats)

        Map.update(
          results,
          mp.tournament_participant_id,
          %{total_stats: stats, stats_changesets_by_round: %{round => stats_changeset}},
          &incorporate_another_round_of_stats(&1, round, stats, stats_changeset)
        )
        |> Map.update!(mp.tournament_participant_id, fn tp_results ->
          first_round_mp =
            Enum.find_value(matches, fn match ->
              match.round == 0 &&
                Enum.find(
                  match.participants,
                  &(&1.tournament_participant_id == mp.tournament_participant_id)
                )
            end)

          Map.merge(tp_results, %{
            first_round_match_id: if(first_round_mp, do: first_round_mp.match_id, else: nil),
            first_round_mp_id: if(first_round_mp, do: first_round_mp.id, else: nil)
          })
        end)
    end
  end

  defp incorporate_another_round_of_stats(tp_results, round, stats, stats_changeset) do
    tp_results
    |> Map.update!(:total_stats, fn total_stats ->
      Map.merge(total_stats, stats, fn
        _k, nil, v2 -> v2
        _k, v1, nil -> v1
        _k, v1, v2 -> Decimal.add(v1, v2)
      end)
    end)
    |> Map.update!(:stats_changesets_by_round, &Map.put(&1, round, stats_changeset))
  end

  @spec log_concise_error_and_verbose_info(
          Socket.t(),
          Ecto.Changeset.t() | String.t(),
          String.t()
        ) :: Socket.t()
  defp log_concise_error_and_verbose_info(socket, error, message) do
    metadata = logger_metadata(socket)
    Logger.info(message <> ". #{inspect(error)}", metadata)
    Logger.error(message, metadata)
    socket
  end

  @spec logger_metadata(Socket.t()) :: map()
  defp logger_metadata(socket) do
    Map.take(socket.assigns, [:tournament_id, :tournament_slug, :stage_id])
  end
end
