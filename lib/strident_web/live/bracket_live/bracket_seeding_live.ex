defmodule StridentWeb.BracketLive.BracketSeedingLive do
  @moduledoc """
  Lets the TO set the "seeding" for a binary-tree stage
  """
  use StridentWeb, :live_component

  require Logger

  alias Strident.BinaryTreeSeeding
  alias Strident.MatchesGeneration
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias StridentWeb.BracketLive.SelectParticipantsModals
  alias StridentWeb.SegmentAnalyticsHelpers

  @seeded_list_id "bracket-seeding-seeded-list"
  @unseeded_list_id "bracket-seeding-unseeded-list"

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    %{
      can_manage_tournament: can_manage_tournament,
      all_participant_details: all_participant_details,
      tournament_id: tournament_id,
      tournament_status: tournament_status,
      stage_id: stage_id,
      tournament_slug: tournament_slug
    } = assigns

    is_connected = connected?(socket)
    read_only = tournament_status not in [:scheduled, :registrations_open, :registrations_closed]

    basic_assigns = %{
      is_connected: is_connected,
      read_only: read_only,
      all_participant_details: all_participant_details,
      show_seed_place_modal_for_seed_index: nil,
      show_participants_modal: false,
      unseeded_participants_only: true,
      unlocked_participants_only: true,
      search_term: nil,
      selected_unseeded_participant_ids: [],
      show_regenerate_button: false,
      stage_id: stage_id,
      tournament_id: tournament_id,
      tournament_slug: tournament_slug
    }

    if is_connected do
      off_track_statuses = Tournaments.off_track_participant_statuses()

      real_tp_details =
        all_participant_details
        |> Map.values()
        |> Enum.reject(&(is_nil(&1.id) or &1.status in off_track_statuses))

      {unseeded_tps, seeded_tps} = Enum.split_with(real_tp_details, &is_nil(&1.seed_index))
      seeded_tps = Enum.sort_by(seeded_tps, & &1.seed_index)

      socket
      |> assign(basic_assigns)
      |> close_confirmation()
      |> copy_parent_assigns(assigns)
      |> assign(%{
        can_manage_tournament: can_manage_tournament,
        seeded_tps: seeded_tps,
        unseeded_tps: unseeded_tps
      })
      |> assign_seed_places_using_seeded_tps_and_unseeded_tps()
      |> assign_inferred_first_round_pairings()
      |> then(&{:ok, &1})
    else
      socket
      |> assign(basic_assigns)
      |> close_confirmation()
      |> then(&{:ok, &1})

      {:ok, socket}
    end
  end

  defp slide_tp_to_position(tp_id, list, position) do
    list
    |> Enum.find_index(&(&1.id == tp_id))
    |> then(&Enum.slide(list, &1, position))
  end

  def list_of_seed_places(real_tp_details) do
    Enum.reduce((Enum.count(real_tp_details) - 1)..0//-1, [], fn seed_index, acc ->
      tp_detail = Enum.find(real_tp_details, &(&1.seed_index == seed_index))
      [{seed_index, tp_detail} | acc]
    end)
  end

  @impl true
  def handle_event("close-confirmation", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> close_confirmation()
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("update-is-seed-index-locked", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{"tp-id" => tp_id, "seed-index" => seed_index, "is-locked" => is_locked} = params
      is_seed_index_locked = is_locked == "true"

      socket
      |> update_seed_index(tp_id, seed_index, is_seed_index_locked)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("lock-all-integer-seed-indexes-clicked", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> assign(%{
        show_confirmation: true,
        confirmation_message: "Please confirm you want to lock 🔒 all seeds.",
        confirmation_confirm_event: "lock-all-integer-seed-indexes"
      })
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("lock-all-integer-seed-indexes", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> lock_or_unlock_all_seeded_tps(true)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("unlock-all-integer-seed-indexes-clicked", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> assign(%{
        show_confirmation: true,
        confirmation_message: "Please confirm you want to unlock 🔓 all seeds.",
        confirmation_confirm_event: "unlock-all-integer-seed-indexes"
      })
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("unlock-all-integer-seed-indexes", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> lock_or_unlock_all_seeded_tps(false)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("show-participants-modal", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> assign(:show_participants_modal, true)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("hide-participants-modal", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> assign(:show_participants_modal, false)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("customize-participants-modal-filters", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{
        "participants_modal_filters" => %{
          "unseeded_only" => unseeded_only,
          "unlocked_only" => unlocked_only
        }
      } = params

      unseeded_participants_only = unseeded_only == "true"
      unlocked_participants_only = unlocked_only == "true"

      socket
      |> assign(%{
        unseeded_participants_only: unseeded_participants_only,
        unlocked_participants_only: unlocked_participants_only
      })
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("toggle-unseeded-participant-selected", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{"select_unseeded_participants" => %{"id" => tp_id, "selected" => selected}} = params
      selected = selected == "true"

      socket
      |> update(:selected_unseeded_participant_ids, fn tp_ids ->
        if selected do
          [tp_id | tp_ids]
        else
          Enum.reject(tp_ids, &(&1 == tp_id))
        end
      end)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("add-selected-unseeded-participants-to-seeds", _params, socket) do
    if socket.assigns.can_manage_tournament do
      %{selected_unseeded_participant_ids: tp_ids} = socket.assigns

      socket
      |> bulk_seed_multiple_participants(tp_ids)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("toggle-all-unseeded-participant-selected", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{"select_all_unseeded_participants" => %{"selected" => selected}} = params
      %{unseeded_tps: unseeded_tps} = socket.assigns
      selected = selected == "true"

      selected_unseeded_participant_ids =
        if selected do
          Enum.map(unseeded_tps, & &1.id)
        else
          []
        end

      socket
      |> assign(:selected_unseeded_participant_ids, selected_unseeded_participant_ids)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  def handle_event("select-single-participant-for-seed-index", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{"select_single_participants" => %{"selected" => tp_id, "seed_index" => seed_index_string}} =
        params

      %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns

      seed_index =
        case seed_index_string do
          nil -> nil
          seed_index_string -> String.to_integer(seed_index_string)
        end

      tp = Enum.find(seeded_tps ++ unseeded_tps, &(&1.id == tp_id))
      tp_attrs = tp |> Map.take([:id, :is_seed_index_locked]) |> Map.put(:seed_index, seed_index)

      tps_to_unseed =
        if is_nil(seed_index) do
          []
        else
          Enum.filter(seeded_tps, &(&1.seed_index == seed_index and &1.id != tp_id))
        end

      tp_attrs_list =
        for tp_to_unseed <- tps_to_unseed do
          tp_to_unseed |> Map.take([:id, :is_seed_index_locked]) |> Map.put(:seed_index, nil)
        end
        |> then(&[tp_attrs | &1])

      socket
      |> do_bulk_update(tp_attrs_list, "Changed participant for seed #{seed_index + 1}")
      |> assign(:show_seed_place_modal_for_seed_index, nil)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  def handle_event("search-unseeded-participants", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{"participants_modal_search" => %{"search_term" => search_term}} = params

      socket
      |> assign(:search_term, search_term)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("show-single-participant-modal", params, socket) do
    if socket.assigns.can_manage_tournament do
      seed_index =
        case Map.get(params, "seed-index") do
          nil ->
            nil

          seed_index_string when is_binary(seed_index_string) ->
            String.to_integer(seed_index_string)
        end

      socket
      |> assign(:show_seed_place_modal_for_seed_index, seed_index)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("hide-single-participant-modal", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> assign(:show_seed_place_modal_for_seed_index, nil)
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("reset-seeds-clicked", _params, socket) do
    if socket.assigns.can_manage_tournament do
      socket
      |> assign(%{
        show_confirmation: true,
        confirmation_message: "Please confirm you want to completely reset the seeds",
        confirmation_confirm_event: "reset-seeds"
      })
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("reset-seeds", _params, socket) do
    if socket.assigns.can_manage_tournament do
      %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns

      tp_attrs_list =
        for %{id: tp_id} <- seeded_tps ++ unseeded_tps do
          %{id: tp_id, seed_index: nil, is_seed_index_locked: false}
        end

      socket
      |> close_confirmation()
      |> do_bulk_update(tp_attrs_list, "Reset seeds")
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("shuffle-unlocked", _params, socket) do
    if socket.assigns.can_manage_tournament do
      %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns
      all_seed_indexes = 0..(Enum.count(seeded_tps) + Enum.count(unseeded_tps) - 1)//1
      {locked_tps, unlocked_tps} = Enum.split_with(seeded_tps, &(!!&1.is_seed_index_locked))
      locked_seed_indexes = Enum.map(locked_tps, & &1.seed_index)
      unlocked_seed_indexes = Enum.reject(all_seed_indexes, &(&1 in locked_seed_indexes))
      usable_seed_indexes = Enum.take(unlocked_seed_indexes, Enum.count(unlocked_tps))
      shuffled_usable_seed_indexes = Enum.shuffle(usable_seed_indexes)

      tp_attrs_list =
        for {%{id: tp_id}, seed_index} <- Enum.zip(unlocked_tps, shuffled_usable_seed_indexes) do
          %{id: tp_id, seed_index: seed_index, is_seed_index_locked: false}
        end

      socket
      |> do_bulk_update(tp_attrs_list, "Shuffled unlocked seeds")
      |> then(&{:noreply, &1})
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @impl true
  def handle_event("seedable-participant-dropped", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{"id" => html_id, "index" => index, "to" => to, "from" => from} = params
      "bracket-seeding-tp-detail-" <> tp_id = html_id

      updated_assigns =
        case {from, to} do
          {@unseeded_list_id, @seeded_list_id} ->
            new_seeded_tp = Enum.find(socket.assigns.unseeded_tps, &(&1.id == tp_id))
            new_unseeded_tps = Enum.reject(socket.assigns.unseeded_tps, &(&1.id == tp_id))
            new_seeded_tps = Enum.slide([new_seeded_tp | socket.assigns.seeded_tps], 0, index)
            %{seeded_tps: new_seeded_tps, unseeded_tps: new_unseeded_tps}

          {@seeded_list_id, @unseeded_list_id} ->
            new_unseeded_tp = Enum.find(socket.assigns.seeded_tps, &(&1.id == tp_id))
            new_seeded_tps = Enum.reject(socket.assigns.seeded_tps, &(&1.id == tp_id))

            new_unseeded_tps =
              Enum.slide([new_unseeded_tp | socket.assigns.unseeded_tps], 0, index)

            %{seeded_tps: new_seeded_tps, unseeded_tps: new_unseeded_tps}

          {@seeded_list_id, @seeded_list_id} ->
            new_seeded_tps = slide_tp_to_position(tp_id, socket.assigns.seeded_tps, index)
            %{seeded_tps: new_seeded_tps}

          {@unseeded_list_id, @unseeded_list_id} ->
            new_unseeded_tps = slide_tp_to_position(tp_id, socket.assigns.unseeded_tps, index)
            %{unseeded_tps: new_unseeded_tps}

          _ ->
            %{}
        end

      socket
      |> assign(updated_assigns)
      |> assign_seed_places_using_seeded_tps_and_unseeded_tps()
      |> assign_inferred_first_round_pairings()
      |> assign(show_regenerate_button: true)
      |> then(&{:noreply, &1})
    else
      socket
      |> berate_javascript_hacker_kid()
      |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("regenerate-matches-with-seeding", _, socket) do
    %{
      tournament_id: tournament_id,
      current_user: current_user,
      can_manage_tournament: can_manage_tournament
    } = socket.assigns

    Logger.info("Going to regenerate matches with seeding", %{
      tournament_id: tournament_id,
      user_id: current_user.id
    })

    if can_manage_tournament do
      %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns
      on_track_statuses = Tournaments.on_track_statuses()
      # tps = seeded_tps ++ Enum.shuffle(unseeded_tps)
      tps = Enum.sort_by(seeded_tps, & &1.seed_index) ++ Enum.shuffle(unseeded_tps)
      on_track_tps = Enum.filter(tps, &(&1.status in on_track_statuses))
      on_track_tp_ids = Enum.map(on_track_tps, & &1.id)

      first_round_pairings =
        BinaryTreeSeeding.seeded_list_to_first_round_pairings(on_track_tp_ids)

      result =
        MatchesGeneration.regenerate_tournament(tournament_id,
          first_round_pairings: first_round_pairings,
          allowed_participant_statuses: on_track_statuses
        )

      socket
      |> then(fn socket ->
        logger_metadata = %{
          user_id: current_user.id,
          tournament_id: tournament_id
        }

        case result do
          {:ok, _, _} ->
            Logger.info("Matches regenerated with seeding", logger_metadata)

            %{tournament_slug: tournament_slug} = socket.assigns

            socket
            |> SegmentAnalyticsHelpers.track_segment_event(
              "Matches regenerated with seeding",
              logger_metadata
            )
            |> put_flash(:info, "Matches regenerated successfully.")
            |> push_navigate(
              to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament_slug)
            )

          {:error, error} ->
            Logger.warning(
              "Error regenerating matches with seeding. #{inspect(error)}",
              logger_metadata
            )

            Logger.warning("Error regenerating matches with seeding", logger_metadata)
            put_error_on_flash(socket, error)
        end
      end)
      |> then(&{:noreply, &1})
    else
      socket
      |> berate_javascript_hacker_kid()
      |> then(&{:noreply, &1})
    end
  end

  defp update_seed_index(socket, tp_id, seed_index, is_seed_index_locked) do
    result = TournamentParticipants.update_seed_index(tp_id, seed_index, is_seed_index_locked)

    case result do
      {:ok, updated_tp} ->
        %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns

        {updated_seeded_tps, updated_unseeded_tps} =
          build_updated_lists({seeded_tps, unseeded_tps}, updated_tp)

        socket
        |> assign(:seeded_tps, updated_seeded_tps)
        |> assign(:unseeded_tps, updated_unseeded_tps)
        |> assign_seed_places_using_seeded_tps_and_unseeded_tps()
        |> assign_inferred_first_round_pairings()
        |> assign(show_regenerate_button: true)

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
  end

  defp build_updated_lists({seeded_tps, unseeded_tps}, updated_tp) do
    seeded_index = Enum.find_index(seeded_tps, &(&1.id == updated_tp.id))
    unseeded_index = Enum.find_index(unseeded_tps, &(&1.id == updated_tp.id))

    updater_map = %{
      seed_index: updated_tp.seed_index,
      is_seed_index_locked: updated_tp.is_seed_index_locked
    }

    case {updated_tp.seed_index, seeded_index, unseeded_index} do
      {nil, seeded_index, nil} when is_integer(seeded_index) ->
        {seeded_tp, updated_seeded_tps} = List.pop_at(seeded_tps, seeded_index)
        updated_unseeded_tps = [Map.merge(seeded_tp, updater_map) | unseeded_tps]
        {updated_seeded_tps, updated_unseeded_tps}

      {seed_index, nil, unseeded_index}
      when is_integer(seed_index) and is_integer(unseeded_index) ->
        {unseeded_tp, updated_unseeded_tps} = List.pop_at(unseeded_tps, unseeded_index)
        updated_seeded_tps = [Map.merge(unseeded_tp, updater_map) | seeded_tps]
        {updated_seeded_tps, updated_unseeded_tps}

      {nil, nil, unseeded_index} when is_integer(unseeded_index) ->
        updated_unseeded_tps =
          List.update_at(unseeded_tps, unseeded_index, &Map.merge(&1, updater_map))

        {seeded_tps, updated_unseeded_tps}

      {seed_index, seeded_index, nil} when is_integer(seed_index) and is_integer(seeded_index) ->
        updated_seeded_tps = List.update_at(seeded_tps, seeded_index, &Map.merge(&1, updater_map))
        {updated_seeded_tps, unseeded_tps}
    end
  end

  defp bulk_seed_multiple_participants(socket, tp_ids) do
    %{tournament_id: tournament_id} = socket.assigns

    case TournamentParticipants.bulk_seed_multiple_participants(tp_ids, tournament_id) do
      {:ok, results} ->
        %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns

        {updated_seeded_tps, updated_unseeded_tps} =
          for {{:update_tp, _tp_id}, updated_tp} <- results,
              reduce: {seeded_tps, unseeded_tps} do
            lists -> build_updated_lists(lists, updated_tp)
          end

        socket
        |> assign(:seeded_tps, updated_seeded_tps)
        |> assign(:unseeded_tps, updated_unseeded_tps)
        |> assign_seed_places_using_seeded_tps_and_unseeded_tps()
        |> assign_inferred_first_round_pairings()
        |> assign(show_regenerate_button: true)
        |> assign(:show_participants_modal, false)
        |> assign(:selected_unseeded_participant_ids, [])
        |> put_flash(:info, "Seeding saved")

      {:error, _, error, _} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
  end

  defp do_bulk_update(socket, tp_attrs_list, _success_message) do
    %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns

    tp_attrs_list
    |> TournamentParticipants.bulk_update_seed_indexes()
    |> then(fn result ->
      case result do
        {:ok, updated_tps} ->
          {unseeded_tps, seeded_tps} =
            build_tp_lists_after_bulk_update(seeded_tps, unseeded_tps, updated_tps)

          socket
          |> assign(:seeded_tps, seeded_tps)
          |> assign(:unseeded_tps, unseeded_tps)
          |> assign_seed_places_using_seeded_tps_and_unseeded_tps()
          |> assign_inferred_first_round_pairings()
          |> assign(show_regenerate_button: true)

        # |> put_flash(:info, success_message)

        {:error, error} ->
          put_error_on_flash(socket, error)
      end
    end)
    |> close_confirmation()
  end

  defp build_tp_lists_after_bulk_update(seeded_tps, unseeded_tps, updated_tps) do
    {unseeded_tps, seeded_tps} =
      (seeded_tps ++ unseeded_tps)
      |> Enum.map(fn tp ->
        case Enum.find(updated_tps, &(&1.id == tp.id)) do
          nil ->
            tp

          updated_tp ->
            tp
            |> Map.put(:seed_index, updated_tp.seed_index)
            |> Map.put(:is_seed_index_locked, updated_tp.is_seed_index_locked)
        end
      end)
      |> Enum.split_with(&is_nil(&1.seed_index))

    seeded_tps = Enum.sort_by(seeded_tps, & &1.seed_index)
    {unseeded_tps, seeded_tps}
  end

  defp lock_or_unlock_all_seeded_tps(socket, is_seed_index_locked) do
    %{seeded_tps: seeded_tps} = socket.assigns

    tp_attrs_list =
      for tp <- seeded_tps do
        tp
        |> Map.take([:id, :seed_index])
        |> Map.put(:is_seed_index_locked, is_seed_index_locked)
      end

    success_message =
      if is_seed_index_locked do
        "Locked all occupied seeds"
      else
        "Unlocked all occupied seeds"
      end

    do_bulk_update(socket, tp_attrs_list, success_message)
  end

  defp assign_seed_places_using_seeded_tps_and_unseeded_tps(socket) do
    %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps} = socket.assigns
    seed_places = list_of_seed_places(seeded_tps ++ unseeded_tps)
    assign(socket, :seed_places, seed_places)
  end

  defp assign_inferred_first_round_pairings(socket) do
    %{seeded_tps: seeded_tps, unseeded_tps: unseeded_tps, stage_id: stage_id} = socket.assigns

    seeded_tp_id_and_seed_indexes =
      seeded_tps
      |> Enum.sort_by(& &1.seed_index)
      |> Enum.map(&Map.take(&1, [:id, :seed_index]))

    unseeded_tp_id_and_seed_indexes = unseeded_tps |> Enum.map(&Map.take(&1, [:id, :seed_index]))

    tp_id_and_seed_indexes =
      seeded_tp_id_and_seed_indexes ++ Enum.shuffle(unseeded_tp_id_and_seed_indexes)

    first_round_pairings =
      Strident.BinaryTreeSeeding.seeded_list_to_first_round_pairings(tp_id_and_seed_indexes)

    first_round_matches =
      first_round_pairings
      |> Enum.with_index()
      |> Enum.map(fn {match_tp_id_and_seed_indexes, label_index} ->
        match_label = Strident.BijectiveHexavigesimal.to_az_string(label_index)

        mps =
          for {%{id: mp_tp_id, seed_index: seed_index}, mp_index} <-
                Enum.with_index(match_tp_id_and_seed_indexes),
              is_integer(seed_index) do
            %{
              id: "theoretical-mp-#{match_label}-#{mp_index}",
              tournament_participant_id: mp_tp_id,
              score: nil,
              rank: nil
            }
          end

        match = %{
          id: "theoretical-match-#{match_label}",
          participants: mps,
          round: 0,
          stage_id: stage_id
        }

        %{match: match, match_label: match_label}
      end)

    assign(socket, :inferred_first_round_matches, first_round_matches)
  end
end
