defmodule StridentWeb.BracketLive do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias Strident.BijectiveHexavigesimal
  alias Strident.Matches
  alias Strident.Matches.Match
  alias Strident.MatchParticipants
  alias Strident.MatchParticipantSwitching
  alias Strident.NotifyClient
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Strident.Tournaments.TournamentParticipant
  alias Strident.Winners
  alias StridentWeb.TournamentPageLive.AssignTransformer
  alias StridentWeb.TournamentPageLive.Components.MarkMatchWinnerConfirmationMessage
  alias Phoenix.LiveView.JS

  @match_preloads [
    :parent_edges,
    participants: [tournament_participant: [:team, :party]]
  ]

  @empty_participant_index_pattern "-index-"
  @expected_number_of_match_participants 2

  @impl true
  def render(assigns) do
    ~H"""
    <.fullscreen_spinner>
      <.flash flash={@flash} class="sticky top-0" />
      <div :if={!@is_connected}>
        <.spinner spinner_id="bracket-spinner" spinner_class="w-24" class="flex justify-center w-full">
        </.spinner>
      </div>
      <div :if={@is_connected} id={"bracket-live-#{@tournament.id}-#{@stage_id}"}>
        <div
          :if={@is_connected and @enable_seeding}
          id="bracket-or-seeding-tab-selection"
          class="mb-6 border-b-2 border-grey-dark"
        >
          <ul class="flex flex-wrap gap-x-8">
            <li
              id="bracket-tab-selector"
              class={[
                "text-center text-3xl font-display uppercase border-b-2",
                if(!@show_seeding,
                  do: "active text-primary border-primary",
                  else:
                    "cursor-pointer text-white border-transparent hover:text-primary hover:border-primary"
                )
              ]}
              phx-click="show-bracket"
            >
              Bracket
            </li>
            <li
              id="seeding-tab-selector"
              class={[
                "text-center text-3xl font-display uppercase border-b-2",
                if(@show_seeding,
                  do: "active text-primary border-primary",
                  else:
                    "cursor-pointer text-white border-transparent hover:text-primary hover:border-primary"
                )
              ]}
              phx-click="show-seeding"
            >
              Seeding
            </li>
          </ul>
        </div>
        <div :if={@show_seeding} id={"bracket-live-seeding-component-#{@stage_id}"}>
          <.live_component
            id={"bracket-seeding-#{@stage_id}"}
            module={StridentWeb.BracketLive.BracketSeedingLive}
            current_user={@current_user}
            can_manage_tournament={@can_manage_tournament}
            stage_id={@stage_id}
            tournament_id={@tournament.id}
            tournament_slug={@tournament.slug}
            tournament_status={@tournament.status}
            all_participant_details={@all_participant_details}
            timezone={@timezone}
            locale={@locale}
            debug_mode={@debug_mode}
          />
        </div>
        <div :if={!@show_seeding} id={"bracket-live-#{@tournament.id}-#{@stage_id}-stage"}>
          <div class="flex space-x-4">
            <div :if={@can_manage_tournament and Enum.any?(@brackets_by_match_type)}>
              <%!-- <p :if={not @edit_mode} class="text-grey-light">
                You are in View mode. To make changes to the bracket, click "Edit Mode":
              </p>
              <p :if={@edit_mode} class="text-secondary">
                You are in Edit mode. To return to View mode, click "View Mode":
              </p>
              <ul :if={@edit_mode} class="ml-8 list-disc text-secondary">
                <li>Click "W" to mark winners.</li>
                <li>Hover over match and click "↺" to reset a match.</li>
                <li>
                  Set scores by writing them in the boxes next to participant names. Scores are saved automatically.
                </li>
              </ul> --%>
              <.button
                :if={not @edit_mode}
                disabled={not @is_connected}
                id="edit-mode-on-bracket-live"
                button_type={:secondary_ghost}
                phx-click="toggle-edit-mode"
                class="my-8"
              >
                Edit
              </.button>
              <.button
                :if={@edit_mode}
                disabled={not @is_connected}
                id="edit-mode-off-bracket-live"
                button_type={:primary_ghost}
                phx-click="toggle-edit-mode"
                class="my-8"
              >
                View
              </.button>
            </div>
            <div class="justify-bottom">
              <.button
                :if={not @edit_mode}
                disabled={not @stale}
                id="stale-data-on-bracket-live"
                button_type={:primary}
                phx-click="update-view"
                class="my-8"
              >
                Update View
              </.button>
            </div>
          </div>

          <.build_stage
            stage_id={find_stage(@tournament, @stage_id).id}
            stage_type={find_stage(@tournament, @stage_id).type}
            all_participant_details={@all_participant_details}
            can_manage_tournament={@can_manage_tournament}
            tournament_status={@tournament.status}
            brackets_by_match_type={@brackets_by_match_type}
            stage_status={@stage_status}
            debug_mode={@debug_mode}
            edit_mode={@edit_mode}
          />
        </div>

        <.live_component
          :if={@show_confirmation}
          id="bracket-live-confirmation"
          module={StridentWeb.Components.Confirmation}
          confirm_event={@confirmation_confirm_event}
          confirm_values={@confirmation_confirm_values}
          message={@confirmation_message}
          timezone={@timezone}
          locale={@locale}
        />
      </div>
    </.fullscreen_spinner>
    """
  end

  @impl true
  def mount(:not_mounted_at_router, session, socket) do
    %{
      "timezone" => timezone,
      "locale" => locale,
      "can_stake" => can_stake,
      "can_play" => can_play,
      "can_wager" => can_wager,
      "is_using_vpn" => is_using_vpn,
      "show_vpn_banner" => show_vpn_banner,
      "check_timezone" => check_timezone
    } = session

    socket
    |> assign_current_user_from_session_token(session)
    |> assign(:timezone, timezone)
    |> assign(:locale, locale)
    |> assign(:can_stake, can_stake)
    |> assign(:can_play, can_play)
    |> assign(:can_wager, can_wager)
    |> assign(:is_using_vpn, is_using_vpn)
    |> assign(:show_vpn_banner, show_vpn_banner)
    |> assign(:check_timezone, check_timezone)
    |> do_mount(%{}, session)
  end

  def mount(params, session, socket) do
    do_mount(socket, params, session)
  end

  def get_tournament(tournament_slug) do
    Tournaments.get_tournament_with_preloads_by([slug: tournament_slug], [
      :participants,
      stages: [matches: @match_preloads]
    ])
  end

  @spec do_mount(Socket.t(), map, map) :: {:ok, Socket.t()}
  defp do_mount(socket, params, session) do
    is_connected = connected?(socket)
    Logger.info("[BRACKET LIVE] mounting with is_connected=#{is_connected}")

    if is_connected do
      %{"tournament_slug" => tournament_slug, "stage_id" => stage_id} = Map.merge(params, session)

      %{
        current_user: current_user
      } = socket.assigns

      tournament = get_tournament(tournament_slug)

      can_manage_tournament = Tournaments.can_manage_tournament?(current_user, tournament)
      stage = Enum.find(tournament.stages, &(&1.id == stage_id))

      enable_seeding = stage.round == 0 and can_manage_tournament

      all_participant_details = build_all_participant_details(tournament.participants)

      socket
      |> assign(:is_connected, is_connected)
      |> assign_debug_mode(params, session)
      |> assign(:tournament, tournament)
      |> assign(:all_participant_details, all_participant_details)
      |> assign(:stage_id, stage_id)
      |> assign(:stage_status, stage.status)
      |> assign_brackets_by_match_type()
      |> assign(:can_manage_tournament, can_manage_tournament)
      |> assign(:enable_seeding, enable_seeding)
      |> assign(:show_seeding, false)
      |> subscribe_to_tournament_updates()
      |> assign(:edit_mode, false)
      |> assign(:stale, false)
      |> close_confirmation()
    else
      socket
      |> assign(:is_connected, is_connected)
    end
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("toggle-edit-mode", _params, socket) do
    socket
    |> update(:edit_mode, &(!&1))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("show-bracket", _params, socket) do
    socket
    |> assign(:show_seeding, false)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("show-seeding", _params, socket) do
    socket
    |> assign(:show_seeding, true)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("mark-match-winner-clicked", %{"id" => id}, socket) do
    %{
      all_participant_details: all_participant_details,
      tournament: tournament,
      stage_id: stage_id
    } = socket.assigns

    match_details =
      tournament.stages
      |> Enum.find(&(&1.id == stage_id))
      |> Map.get(:matches)
      |> Enum.find(&Enum.any?(&1.participants, fn mp -> mp.id == id end))

    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_message:
        mark_match_winner_confirmation_message(
          match_details,
          all_participant_details,
          id
        ),
      confirmation_confirm_event: "mark-match-winner",
      confirmation_confirm_values: %{"id" => id}
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("mark-match-winner", %{"id" => id}, socket) do
    socket
    |> mark_match_winner(id)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("set-match-participant-score", %{"id" => id, "score" => score}, socket) do
    socket
    |> set_match_participant_score(id, score)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reset-match-clicked", %{"id" => id}, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_message: "Are you sure you want to reset this match?",
      confirmation_confirm_event: "reset-match",
      confirmation_confirm_values: %{"id" => id}
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reset-match", %{"id" => id}, socket) do
    socket
    |> reset_match(id)
    |> close_confirmation()
    |> push_event("show-spinner", %{})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "match-participant-swapped",
        %{"from" => same_participant, "to" => same_participant},
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("match-participant-swapped", params, socket) do
    if socket.assigns.can_manage_tournament do
      %{tournament: tournament, stage_id: stage_id} = socket.assigns
      stage = find_stage(tournament, stage_id)

      get_match = fn id ->
        Enum.find(stage.matches, fn match ->
          Enum.any?(match.participants, &(&1.id == id))
        end)
      end

      result =
        case params do
          %{
            "from" => "match-participant-" <> from_match_participant_id,
            "to" => "match-participant-" <> to_match_participant_id
          } ->
            from_match = get_match.(from_match_participant_id)
            to_match = get_match.(to_match_participant_id)

            if from_match.id == to_match.id do
              {:ok, :noop}
            else
              from_match_participant =
                Enum.find(from_match.participants, &(&1.id == from_match_participant_id))

              to_match_participant =
                Enum.find(to_match.participants, &(&1.id == to_match_participant_id))

              MatchParticipantSwitching.swap(from_match_participant, to_match_participant)
            end

          %{
            "from" => "match-participant-" <> from_match_participant_id,
            "to" => "empty-switchable-participant-" <> to_match_id_and_index
          } ->
            [to_match_id | _] =
              String.split(to_match_id_and_index, @empty_participant_index_pattern)

            from_match = get_match.(from_match_participant_id)

            if from_match.id == to_match_id do
              {:ok, :noop}
            else
              to_match = Enum.find(stage.matches, &(&1.id == to_match_id))

              from_match_participant =
                Enum.find(from_match.participants, &(&1.id == from_match_participant_id))

              MatchParticipantSwitching.move_to_match(from_match_participant, to_match)
            end

          %{
            "from" => "empty-switchable-participant-" <> from_match_id_and_index,
            "to" => "match-participant-" <> to_match_participant_id
          } ->
            [from_match_id | _] =
              String.split(from_match_id_and_index, @empty_participant_index_pattern)

            to_match = get_match.(to_match_participant_id)

            if from_match_id == to_match.id do
              {:ok, :noop}
            else
              from_match = Enum.find(stage.matches, &(&1.id == from_match_id))

              to_match_participant =
                Enum.find(to_match.participants, &(&1.id == to_match_participant_id))

              MatchParticipantSwitching.move_to_match(to_match_participant, from_match)
            end
        end

      case result do
        {:ok, :noop} ->
          socket
          |> push_event("close-spinner", %{})
          |> then(&{:noreply, &1})

        {:ok, _} ->
          socket
          |> put_flash(:info, "Switched participants")
          |> then(&{:noreply, &1})

        {:error, _, error, _} ->
          socket
          |> push_event("close-spinner", %{})
          |> put_string_or_changeset_error_in_flash(error)
          |> then(&{:noreply, &1})
      end
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  def handle_event("update-view", _, socket) do
    tournament = get_tournament(socket.assigns.tournament.slug)
    all_participant_details = build_all_participant_details(tournament.participants)

    socket
    |> assign(:tournament, tournament)
    |> assign(:all_participant_details, all_participant_details)
    |> assign_brackets_by_match_type()
    |> assign(:stale, false)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_participant_updated, details}, socket) do
    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_updated_match_participant(
        tournament,
        details
      )
    end)
    |> assign_brackets_by_match_type()
    |> push_event("close-spinner", %{})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_participant_deleted, details}, socket) do
    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_deleted_match_participant(
        tournament,
        details
      )
    end)
    |> assign_brackets_by_match_type()
    |> push_event("close-spinner", %{})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_participants_swapped, details}, socket) do
    %{updated_match_participant_1: mp_1, updated_match_participant_2: mp_2, stage_id: stage_id} =
      details

    %{match_id: match_id_1} = mp_1
    %{match_id: match_id_2} = mp_2
    %{assigns: %{tournament: tournament}} = socket

    updated_stages =
      Enum.map(tournament.stages, fn stage ->
        if stage.id == stage_id do
          updated_matches =
            Enum.map(stage.matches, fn
              %{id: match_id} = match when match_id == match_id_1 ->
                updated_participants =
                  Enum.map(match.participants, &if(&1.id == mp_2.id, do: mp_1, else: &1))

                %{match | participants: updated_participants}

              %{id: match_id} = match when match_id == match_id_2 ->
                updated_participants =
                  Enum.map(match.participants, &if(&1.id == mp_1.id, do: mp_2, else: &1))

                %{match | participants: updated_participants}

              match ->
                match
            end)

          %{stage | matches: updated_matches}
        else
          stage
        end
      end)

    socket
    |> update(:tournament, fn _ -> %{tournament | stages: updated_stages} end)
    |> assign_brackets_by_match_type()
    |> push_event("close-spinner", %{})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_participant_moved_to_match, details}, socket) do
    %{
      id: mp_id,
      original_match_id: original_match_id,
      new_match_id: new_match_id,
      stage_id: stage_id
    } = details

    %{assigns: %{tournament: tournament}} = socket
    stage = Enum.find(tournament.stages, &(&1.id == stage_id))
    original_match = Enum.find(stage.matches, &(&1.id == original_match_id))
    mp = Enum.find(original_match.participants, &(&1.id == mp_id))

    updated_stages =
      Enum.map(tournament.stages, fn stage ->
        if stage.id == stage_id do
          updated_matches =
            Enum.map(stage.matches, fn match ->
              cond do
                match.id == original_match_id ->
                  updated_participants = Enum.reject(match.participants, &(&1.id == mp_id))
                  %{match | participants: updated_participants}

                match.id == new_match_id ->
                  updated_participants = match.participants ++ [mp]

                  %{match | participants: updated_participants}

                true ->
                  match
              end
            end)

          %{stage | matches: updated_matches}
        else
          stage
        end
      end)

    socket
    |> update(:tournament, fn _ -> %{tournament | stages: updated_stages} end)
    |> assign_brackets_by_match_type()
    |> push_event("close-spinner", %{})
    |> then(&{:noreply, &1})
  end

  # TODO: This can be deleted when we think there are no bad inpacts
  # CHANGED THIS FUNCTION TO MARK DATA STALE
  # @impl true
  # def handle_info({:match_winner, details}, socket) do
  #   # only do the update after broadcast if not this PID
  #   if Map.get(details, :pid) == self() do
  #     {:noreply, socket}
  #   else
  #     socket
  #     |> update(:tournament, fn tournament ->
  #       AssignTransformer.transform_tournament_assign_with_match_winner(tournament, details)
  #     end)
  #     |> ensure_all_participants_details_are_known(details)
  #     |> assign_brackets_by_match_type()
  #     |> then(&{:noreply, &1})
  #   end
  # end

  @impl true
  def handle_info({:match_winner, details}, socket) do
    # only mark as stale after broadcast if not this PID
    if Map.get(details, :pid) == self() do
      {:noreply, socket}
    else
      socket
      |> assign(:stale, true)
      |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_info({:ok, {:match_winner, details}}, socket) do
    # only do the update for the direct `send` to this PID
    %{all_participant_details: all_participant_details} = socket.assigns
    %{match_id: match_id, updated_winners: [updated_winner | _]} = details
    %{name: name} = Map.get(all_participant_details, updated_winner.tournament_participant_id)

    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_match_winner(tournament, details)
    end)
    |> ensure_all_participants_details_are_known(details)
    |> assign_brackets_by_match_type()
    |> close_confirmation()
    |> push_event("close-spinner", %{})
    |> track_segment_event("Marked Match Winner", %{
      match_participant_id: updated_winner.id,
      match_id: match_id,
      tournament_id: socket.assigns.tournament.id
    })
    |> put_flash(:info, "Marked winner #{name}")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:error, {:match_winner, error}}, socket) do
    socket
    |> close_confirmation()
    |> push_event("close-spinner", %{})
    |> put_string_or_changeset_error_in_flash(error)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:tournament_invitation_updated, _invitation}, socket) do
    socket
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:tournament_matches_regenerated, details}, socket) do
    %{tournament_id: tournament_id} = details
    %{tournament: tournament} = socket.assigns

    if tournament.id == tournament_id do
      tournament = get_tournament(tournament.slug)

      socket
      |> assign_brackets_by_match_type()
      |> assign(:tournament, tournament)
      |> put_flash(:info, "Tournament regenerated, syncing view...")
      |> then(&{:noreply, &1})
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({ref, _result}, socket) when is_reference(ref) do
    # https://hexdocs.pm/elixir/main/Task.Supervisor.html#async_nolink/3-compatibility-with-otp-behaviours
    {:noreply, socket}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, socket) do
    # https://hexdocs.pm/elixir/main/Task.Supervisor.html#async_nolink/3-compatibility-with-otp-behaviours
    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    Logger.info("Unhandled messages in bracket handle_info. #{inspect(message)}")
    Logger.warning("Unhandled messages in bracket handle_info")

    socket
    |> push_event("close-spinner", %{})
    |> then(&{:noreply, &1})
  end

  @spec build_all_participant_details([TournamentParticipant.t()]) :: %{
          TournamentParticipant.id() => map()
        }
  defp build_all_participant_details(tps) do
    Enum.reduce(tps, %{}, fn tp, all_participant_details ->
      tp
      |> build_participant_detail_map()
      |> then(&Map.put(all_participant_details, tp.id, &1))
    end)
  end

  @spec build_participant_detail_map(TournamentParticipant.t()) :: map()
  defp build_participant_detail_map(tp) do
    %{
      id: tp.id,
      name: TournamentParticipants.participant_name(tp),
      email: TournamentParticipants.participant_email(tp),
      inserted_at: tp.inserted_at,
      logo_url: TournamentParticipants.participant_logo_url(tp),
      seed_index: tp.seed_index,
      is_seed_index_locked: tp.is_seed_index_locked,
      status: tp.status
    }
  end

  defp ensure_all_participants_details_are_known(socket, details) do
    %{all_participant_details: all_participant_details, tournament: tournament} = socket.assigns
    %{child_participants: child_participants} = details
    %{participants: tps} = tournament
    known_detail_ids = Map.keys(all_participant_details)

    missing_ids =
      child_participants
      |> Enum.map(& &1.tournament_participant_id)
      |> Enum.filter(&(&1 not in known_detail_ids))

    if Enum.any?(missing_ids) do
      update(socket, :all_participant_details, fn all_participant_details ->
        Enum.reduce(missing_ids, all_participant_details, fn tp_id, all_participant_details ->
          tps
          |> Enum.find(tps, &(&1.id == tp_id))
          |> build_participant_detail_map()
          |> then(&Map.put(all_participant_details, tp_id, &1))
        end)
      end)
    else
      socket
    end
  end

  defp assign_brackets_by_match_type(socket) do
    %{tournament: tournament, stage_id: stage_id} = socket.assigns
    stage = find_stage(tournament, stage_id)

    brackets_by_match_type =
      for {match_type, matches} <- Enum.group_by(stage.matches, & &1.type), reduce: %{} do
        brackets_details ->
          sorted_matches_by_round = group_by_round_sorted_last_round_to_first(matches)

          match_counts_by_sorted_rounds =
            sorted_matches_by_round
            |> Enum.map(&{elem(&1, 0), Enum.count(elem(&1, 1))})
            |> Enum.sort_by(&elem(&1, 0), :asc)

          {displayed_matches, hidden_matches, match_label, _prev_index} =
            for {_round, matches} <- sorted_matches_by_round,
                match <- matches,
                reduce: {[], [], %{}, -1} do
              {displayed_matches, hidden_matches, map, prev_index} ->
                if display_match_in_view_mode?(match, stage.status) do
                  index = prev_index + 1
                  name = BijectiveHexavigesimal.to_az_string(index)
                  new_map = Map.put(map, match.id, %{name: name, index: index})
                  new_displayed_matches = [match | displayed_matches]
                  {new_displayed_matches, hidden_matches, new_map, index}
                else
                  new_hidden_matches = [match | hidden_matches]
                  new_map = Map.put(map, match.id, %{name: nil, index: nil})
                  {displayed_matches, new_hidden_matches, new_map, prev_index}
                end
            end

          matches = Enum.reverse(displayed_matches) ++ Enum.reverse(hidden_matches)

          grand_final_was_reset =
            case match_counts_by_sorted_rounds do
              [{_, 1}, {_, 1}, {_, 1} | _] -> true
              _ -> false
            end

          last_match = Enum.max_by(matches, & &1.round, fn -> nil end)

          details = %{
            matches: matches,
            match_counts_by_sorted_rounds: match_counts_by_sorted_rounds,
            grand_final_was_reset: grand_final_was_reset,
            last_match: last_match,
            labels_by_match_id: match_label
          }

          Map.put(brackets_details, match_type, details)
      end

    assign(socket, :brackets_by_match_type, brackets_by_match_type)
  end

  defp find_stage(tournament, stage_id), do: Enum.find(tournament.stages, &(&1.id == stage_id))

  defp subscribe_to_tournament_updates(%{assigns: %{tournament: tournament}} = socket) do
    tap(socket, fn _ ->
      if connected?(socket) do
        NotifyClient.subscribe_to_events_affecting(tournament)
      end
    end)
  end

  defp set_match_participant_score(socket, id, score) do
    if socket.assigns.can_manage_tournament do
      case id
           |> MatchParticipants.get_match_participant()
           |> MatchParticipants.update_match_participant(%{score: score}) do
        {:ok, match_participant} ->
          socket
          |> track_segment_event("Set Match Participant Score", %{
            match_participant_id: match_participant.id,
            match_id: match_participant.match_id,
            score: score
          })
          |> put_flash(:info, "Score set!")

        {:error, error} ->
          socket
          |> push_event("close-spinner", %{})
          |> put_string_or_changeset_error_in_flash(error)

        _ ->
          socket
          |> push_event("close-spinner", %{})
          |> put_flash(
            :error,
            "Could not update score. Please reload the page and try again."
          )
      end
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  defp find_parents_in_matches(match, matches) do
    parent_ids = Enum.map(match.parent_edges, & &1.parent_id)
    Enum.filter(matches, &(&1.id in parent_ids))
  end

  defp reset_match(socket, match_id) do
    %{assigns: %{can_manage_tournament: can_manage_tournament}} = socket

    if can_manage_tournament do
      case [id: match_id]
           |> Matches.get_match_with_preloads_by([:participants, children: :participants])
           |> Matches.reset_match() do
        {:ok, _final_effect, _all_effects} ->
          socket
          |> track_segment_event("Reset Match", %{match_id: match_id})
          |> put_flash(:info, "Reset match!")

        {:error, message} when is_binary(message) ->
          put_flash(socket, :error, message)

        {:error, %Ecto.Changeset{} = changeset} ->
          put_humanized_changeset_errors_in_flash(socket, changeset)
      end
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  defp mark_match_winner_confirmation_message(
         match_details,
         all_participant_details,
         match_winner_id
       ) do
    {winner_name, scores} =
      Enum.reduce(match_details.participants, {nil, []}, fn
        %{id: mp_id} = mp_detail, {winner_name, scores_list} ->
          {_id, %{name: name}} =
            Enum.find(
              all_participant_details,
              &(elem(&1, 0) == mp_detail.tournament_participant_id)
            )

          score = Map.get(mp_detail, :score)
          winner_name = if mp_id == match_winner_id, do: name, else: winner_name
          {winner_name, [%{name: name, score: score} | scores_list]}
      end)

    MarkMatchWinnerConfirmationMessage.mark_match_winner_confirmation_message(%{
      winner_name: winner_name,
      scores: scores
    })
  end

  defp mark_match_winner(socket, match_participant_id) do
    %{can_manage_tournament: can_manage_tournament} = socket.assigns

    if can_manage_tournament do
      socket
      |> tap(fn _ ->
        match_participant = MatchParticipants.get_match_participant(match_participant_id)
        Winners.mark_match_winner(match_participant, self())
      end)
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  defp sorted_brackets_by_match_type(brackets_by_match_type) do
    Enum.sort_by(brackets_by_match_type, fn
      {:lower, _} -> 1
      _ -> 0
    end)
  end

  @type sibling_matches :: {Match.round(), [Match.t()]}

  @spec group_by_round_sorted_last_round_to_first([Match.t()]) :: [sibling_matches()]
  defp group_by_round_sorted_last_round_to_first(same_type_matches) do
    same_type_matches
    |> Enum.group_by(& &1.round)
    |> Enum.sort_by(&elem(&1, 0), :desc)
    |> Enum.reduce([], fn {round, siblings}, acc ->
      [{round, sort_by_child_sorting(siblings, acc)} | acc]
    end)
  end

  @spec sort_by_child_sorting(sibling_matches(), [sibling_matches()]) :: [sibling_matches()]
  defp sort_by_child_sorting(latest_round_matches, []), do: latest_round_matches

  defp sort_by_child_sorting(siblings, [{_parent_round, [_single_child]} | _]) do
    siblings
  end

  defp sort_by_child_sorting(siblings, [{_parent_round, sorted_children} | _]) do
    Enum.sort_by(siblings, fn
      %{id: id} ->
        Enum.find_index(sorted_children, fn %{parent_edges: parent_edges} ->
          Enum.any?(parent_edges, &(&1.parent_id == id))
        end)

      _ ->
        nil
    end)
  end

  defp filtered_display_parents(parents, stage_status, edit_mode) do
    if edit_mode do
      parents
    else
      Enum.filter(parents, &display_match_in_view_mode?(&1, stage_status))
    end
  end

  defp display_match_in_view_mode?(_match, :scheduled) do
    true
  end

  defp display_match_in_view_mode?(match, _stage_status) do
    is_finised = Matches.is_match_finished?(match)
    mp_count = Enum.count(match.participants)

    (is_finised and mp_count == @expected_number_of_match_participants) or
      (not is_finised and
         not (mp_count == 0 and Enum.empty?(match.parent_edges)))
  end

  attr(:stage_id, :string, required: true)
  attr(:stage_type, :atom, required: true)
  attr(:all_participant_details, :map, required: true)
  attr(:can_manage_tournament, :boolean, required: true)
  attr(:tournament_status, :atom, required: true)
  attr(:brackets_by_match_type, :map, required: true)
  attr(:stage_status, :atom, required: true)
  attr(:debug_mode, :boolean, required: true)
  attr(:edit_mode, :boolean, required: true)

  defp build_stage(assigns) do
    ~H"""
    <div
      class="overflow-scroll container-xl scroll-auto scrollbar-hidden"
      x-data="bracketLiveParticipant"
    >
      <.focus_wrap id={"matches-and-parents-focus-wrap-#{@stage_id}"}>
        <div
          :for={
            {match_type,
             %{
               matches: matches,
               last_match: last_match,
               match_counts_by_sorted_rounds: match_counts_by_sorted_rounds,
               grand_final_was_reset: grand_final_was_reset,
               labels_by_match_id: labels_by_match_id
             }} <-
              sorted_brackets_by_match_type(@brackets_by_match_type)
          }
          class="w-full overflow-scroll scrollbar-hidden"
        >
          <.build_rounds
            match_counts_by_sorted_rounds={match_counts_by_sorted_rounds}
            match_type={match_type}
            grand_final_was_reset={grand_final_was_reset}
          />
          <.build_match_and_parents
            match={last_match}
            matches={matches}
            parents={find_parents_in_matches(last_match, matches)}
            all_participant_details={@all_participant_details}
            can_manage_tournament={@can_manage_tournament}
            tournament_status={@tournament_status}
            labels_by_match_id={labels_by_match_id}
            stage_status={@stage_status}
            debug_mode={@debug_mode}
            edit_mode={@edit_mode}
          />
        </div>
      </.focus_wrap>
    </div>
    """
  end

  attr(:match_type, :atom, required: true)
  attr(:match_counts_by_sorted_rounds, :list, required: true)
  attr(:grand_final_was_reset, :boolean, required: true)

  defp build_rounds(assigns) do
    ~H"""
    <div class="flex w-full gap-1 ml-4">
      <div
        :for={{round, _match_count} <- @match_counts_by_sorted_rounds}
        class="flex-none text-center border w-80 bg-grey-medium border-grey-dark"
      >
        <div :if={@match_type == :lower}>
          <p :if={round < Enum.count(@match_counts_by_sorted_rounds) - 1}>
            Lower Bracket R<%= round + 1 %>
          </p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 1}>Lower Bracket Final</p>
        </div>

        <div :if={@match_type == :upper and not @grand_final_was_reset}>
          <p :if={round < Enum.count(@match_counts_by_sorted_rounds) - 2}>
            Upper Bracket R<%= round + 1 %>
          </p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 2}>Upper Bracket Final</p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 1}>Grand Final</p>
        </div>

        <div :if={@match_type == :upper and @grand_final_was_reset}>
          <p :if={round < Enum.count(@match_counts_by_sorted_rounds) - 3}>
            Upper Bracket R<%= round + 1 %>
          </p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 3}>Upper Bracket Final</p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 2}>Grand Final</p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 1}>Grand Final Reset</p>
        </div>

        <div :if={@match_type == :standard}>
          <p :if={round < Enum.count(@match_counts_by_sorted_rounds) - 2}>Round <%= round + 1 %></p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 2}>Semifinals</p>
          <p :if={round == Enum.count(@match_counts_by_sorted_rounds) - 1}>Grand Final</p>
        </div>
      </div>
    </div>
    """
  end

  attr(:match, Match, required: true)
  attr(:matches, :list, required: true)
  attr(:all_participant_details, :map, required: true)
  attr(:parents, :list, required: true)
  attr(:can_manage_tournament, :boolean, required: true)
  attr(:tournament_status, :atom, required: true)
  attr(:debug_mode, :boolean, required: true)
  attr(:edit_mode, :boolean, required: true)
  attr(:labels_by_match_id, :map, required: true)
  attr(:stage_status, :atom, required: true)

  attr(:after_match_horizontal_line, :string,
    default:
      "after:content-[''] after:absolute after:w-4 after:h-px after:left-0 after:top-1/2 after:bg-grey-light after:-translate-x-full after:only:hidden"
  )

  attr(:before_match_horizontal_line, :string,
    default:
      "before:content-[''] before:absolute before:bg-grey-light before:right-0 before:top-1/2 before:translate-x-full before:w-4 before:h-px"
  )

  attr(:after_match_vertical_line, :string,
    default:
      "after:content-[''] after:absolute after:bg-grey-light after:-right-4 after:top-1/2 after:w-px after:h-full after:last:-translate-y-full"
  )

  attr(:after_match_vertical_half_line, :string,
    default:
      "after:content-[''] after:absolute after:bg-grey-light after:-right-4 after:top-1/2 after:w-px after:h-[58%] after:last:-translate-y-full"
  )

  defp build_match_and_parents(assigns) do
    ~H"""
    <div class="flex flex-row-reverse w-fit">
      <div class={[
        "relative ml-8 flex items-center group/match",
        if(@parents |> filtered_display_parents(@stage_status, @edit_mode) |> Enum.any?(),
          do: @after_match_horizontal_line
        )
      ]}>
        <div class="border-[1px] rounded-l-lg px-1 border-grilla-blue text-grilla-pink min-w-[20]">
          <%= @labels_by_match_id |> Map.get(@match.id, %{}) |> Map.get(:name) %>
        </div>

        <div class="flex items-center">
          <.build_match
            match={@match}
            all_participant_details={@all_participant_details}
            is_match_finished={Matches.is_match_finished?(@match)}
            can_manage_tournament={@can_manage_tournament}
            tournament_status={@tournament_status}
            stage_status={@stage_status}
            edit_mode={@edit_mode}
            debug_mode={@debug_mode}
          />

          <.button
            :if={
              Matches.is_match_finished?(@match) and @can_manage_tournament and not @debug_mode and
                @edit_mode
            }
            button_type={:primary_ghost}
            id={"reset-match-#{@match.id}"}
            phx-click="reset-match-clicked"
            phx-value-id={@match.id}
            title="Reset match"
            class="absolute invisible px-0 py-0 text-2xl group-focus/match:visible group-hover/match:visible group-active/match:visible -right-4 bg-blackish hover:bg-grey-light "
          >
            ↺
          </.button>
        </div>
      </div>

      <div :if={Enum.any?(@parents)} class="flex flex-col justify-center">
        <div
          :for={parent <- filtered_display_parents(@parents, @stage_status, @edit_mode)}
          class={[
            "flex items-start justify-end mt-1.5 mb-1.5 relative",
            @before_match_horizontal_line,
            cond do
              Enum.count(filtered_display_parents(@parents, @stage_status, @edit_mode)) > 1 ->
                @after_match_vertical_line

              Enum.count(@parents) > 1 and
                  Enum.count(filtered_display_parents(@parents, @stage_status, @edit_mode)) == 1 ->
                @after_match_vertical_half_line

              true ->
                nil
            end
          ]}
        >
          <.build_match_and_parents
            match={parent}
            matches={@matches}
            parents={find_parents_in_matches(parent, @matches)}
            all_participant_details={@all_participant_details}
            can_manage_tournament={@can_manage_tournament}
            tournament_status={@tournament_status}
            labels_by_match_id={@labels_by_match_id}
            stage_status={@stage_status}
            debug_mode={@debug_mode}
            edit_mode={@edit_mode}
          />
        </div>

        <.add_empty_slots
          parents={@parents}
          filtered_parents_ids={
            @parents |> filtered_display_parents(@stage_status, @edit_mode) |> Enum.map(& &1.id)
          }
          matches={@matches}
          edit_mode={@edit_mode}
          stage_status={@stage_status}
        />
      </div>
    </div>
    """
  end

  attr(:parents, :list, required: true)
  attr(:filtered_parents_ids, :list, required: true)
  attr(:matches, :list, required: true)
  attr(:edit_mode, :boolean, required: true)
  attr(:stage_status, :atom, required: true)

  defp add_empty_slots(assigns) do
    rejected_parents = Enum.reject(assigns.parents, &(&1.id in assigns.filtered_parents_ids))
    assigns = assign(assigns, :rejected_parents, rejected_parents)

    ~H"""
    <div
      :for={parent <- @rejected_parents}
      class={[
        "flex items-start justify-end",
        if(parent.type != :lower, do: "mt-1.5 mb-1.5", else: "mt-2")
      ]}
    >
      <div class="h-[56px] p-px">
        &nbsp;
      </div>

      <div
        :if={
          parent
          |> find_parents_in_matches(@matches)
          |> Enum.filter(&(&1.type == parent.type))
          |> Enum.any?()
        }
        class={["flex flex-col", if(parent.type != :lower, do: "mt-1.5 mb-1.5")]}
      >
        <.add_empty_slots
          parents={
            parent
            |> find_parents_in_matches(@matches)
            |> Enum.filter(&(&1.type == parent.type))
          }
          filtered_parents_ids={
            parent
            |> find_parents_in_matches(@matches)
            |> Enum.filter(&(&1.type == parent.type))
            |> filtered_display_parents(@stage_status, @edit_mode)
            |> Enum.map(& &1.id)
          }
          matches={@matches}
          edit_mode={@edit_mode}
          stage_status={@stage_status}
        />
      </div>
    </div>
    """
  end

  attr(:match, :any, required: true)
  attr(:is_match_finished, :boolean, required: true)
  attr(:all_participant_details, :map, required: true)

  attr(:expected_number_of_match_participants, :integer,
    default: @expected_number_of_match_participants
  )

  attr(:can_manage_tournament, :boolean, required: true)
  attr(:tournament_status, :atom, required: true)
  attr(:stage_status, :atom, required: true)
  attr(:debug_mode, :boolean, required: true)
  attr(:edit_mode, :boolean, required: true)

  def build_match(assigns) do
    ~H"""
    <div
      id={"bracket-live-match-#{@match.id}"}
      class={[
        "rounded-md ",
        if(@is_match_finished,
          do: "border border-primary",
          else: "p-px bg-gradient-to-l from-[#03d5fb] to-[#ff6802]"
        )
      ]}
    >
      <.match_details_modal
        :if={@debug_mode}
        match={@match}
        all_participant_details={@all_participant_details}
        debug_mode={@debug_mode}
      />
      <div class="grid w-64 grid-cols-1 text-white divide-y-2 divide-black rounded-md bg-grey-medium">
        <.build_participant
          :for={participant <- @match.participants}
          match_participant_id={participant.id}
          match_participant_score={participant.score}
          match_participant_rank={participant.rank}
          participant_details={
            Map.get(@all_participant_details, participant.tournament_participant_id)
          }
          is_match_finished={@is_match_finished}
          match_round={@match.round}
          can_manage_tournament={@can_manage_tournament}
          tournament_status={@tournament_status}
          stage_id={@match.stage_id}
          stage_status={@stage_status}
          edit_mode={@edit_mode}
          debug_mode={@debug_mode}
        />

        <.build_empty_participant
          :for={
            index <- 1..(@expected_number_of_match_participants - Enum.count(@match.participants))//1
          }
          :if={Enum.count(@match.participants) < @expected_number_of_match_participants}
          is_match_finished={@is_match_finished}
          match_id={@match.id}
          match_round={@match.round}
          stage_id={@match.stage_id}
          can_manage_tournament={@can_manage_tournament}
          index={index}
          edit_mode={@edit_mode}
          debug_mode={@debug_mode}
        />
      </div>
    </div>
    """
  end

  attr(:is_match_finished, :boolean, required: true)
  attr(:match_round, :integer, required: true)
  attr(:match_id, :string, required: true)
  attr(:stage_id, :string, required: true)
  attr(:can_manage_tournament, :boolean, required: true)
  attr(:index, :integer, required: true)
  attr(:empty_participant_index_pattern, :string, default: @empty_participant_index_pattern)
  attr(:debug_mode, :boolean, required: true)
  attr(:edit_mode, :boolean, required: true)

  defp build_empty_participant(assigns) do
    ~H"""
    <div
      id={"empty-switchable-participant-#{@match_id}#{@empty_participant_index_pattern}#{@index}"}
      phx-hook="Sortable"
      data-sortable-group={"participant-switching-#{@stage_id}"}
      data-show-spinner-on-drop="yes"
      data-use-swap-plugin="yes"
      data-event-to-send-on-drop="match-participant-swapped"
    >
      <div
        :if={@edit_mode and not @is_match_finished and @match_round == 0 and @can_manage_tournament}
        class="text-center draggable sortable-filtered sortable-handle text-grey-light"
      >
        TBD
      </div>

      <div
        :if={@is_match_finished or @match_round > 0 or not @can_manage_tournament or not @edit_mode}
        class="text-center text-grey-light"
      >
        TBD
      </div>
    </div>
    """
  end

  attr(:match_participant_id, :string, required: true)
  attr(:match_participant_score, :any, required: true)
  attr(:match_participant_rank, :any, required: true)
  attr(:participant_details, :map, required: true)
  attr(:is_match_finished, :boolean, required: true)
  attr(:match_round, :integer, required: true)
  attr(:can_manage_tournament, :boolean, required: true)
  attr(:stage_id, :string, required: true)
  attr(:tournament_status, :atom, required: true)
  attr(:stage_status, :atom, required: true)
  attr(:debug_mode, :boolean, required: true)
  attr(:edit_mode, :boolean, required: true)

  defp build_participant(assigns) do
    ~H"""
    <div
      id={"match-participant-#{@match_participant_id}"}
      class={[
        "flex items-center justify-between py-0.5 px-1",
        if(@match_participant_rank == 0, do: "text-primary")
      ]}
      phx-hook="Sortable"
      data-sortable-group={"participant-switching-#{@stage_id}"}
      data-show-spinner-on-drop="yes"
      data-use-swap-plugin="yes"
      data-event-to-send-on-drop="match-participant-swapped"
    >
      <.button
        :if={
          @edit_mode and @can_manage_tournament and not @is_match_finished and not @debug_mode and
            @tournament_status == :in_progress and @stage_status == :in_progress
        }
        button_type={:primary}
        id={"match-participant-winner-button-#{@match_participant_id}"}
        phx-click="mark-match-winner-clicked"
        phx-value-id={@match_participant_id}
        class="h-full px-0 py-0 mx-2 text-sm"
      >
        W
      </.button>
      <div
        :if={
          @edit_mode and not @is_match_finished and @match_round == 0 and not @debug_mode and
            @can_manage_tournament
        }
        id={"switchable-participant-#{@match_participant_id}"}
        draggable="true"
        class="flex text-sm truncate rounded sortable-handle draggable cursor-grab grow "
        x-bind="participantLabel"
        x-bind:class={"hoveredParticipantId === '#{@participant_details.id}' ? 'bg-grey-light' : ''"}
        data-participant-id={@participant_details.id}
      >
        <.image
          id={"participant-logo-#{@match_participant_id}"}
          image_url={@participant_details.logo_url}
          alt="logo"
          class="mr-2 border-2 border-black rounded-full bg-gray-dark"
          width={10}
          height={10}
        />
        <%= @participant_details.name %>
      </div>

      <div
        :if={
          @is_match_finished or @match_round > 0 or @debug_mode or not @can_manage_tournament or
            not @edit_mode
        }
        class="flex text-sm truncate rounded cursor-pointer grow"
        x-bind="participantLabel"
        x-bind:class={"hoveredParticipantId === '#{@participant_details.id}' ? 'bg-grey-light' : ''"}
        data-participant-id={@participant_details.id}
      >
        <.image
          id={"participant-logo-#{@match_participant_id}"}
          image_url={@participant_details.logo_url}
          alt="logo"
          class="mr-2 border-2 border-black rounded-full bg-gray-dark"
          width={16}
          height={16}
        />
        <%= @participant_details.name %>
      </div>

      <form
        :if={
          @tournament_status in [:in_progress, :under_review, :finished, :cancelled] and
            @stage_status in [:in_progress, :requires_tiebreaking, :finished]
        }
        id={"match-participant-score-input-#{@match_participant_id}-form"}
        phx-change="set-match-participant-score"
      >
        <input
          class="hidden"
          type="text"
          name="id"
          value={@match_participant_id}
          disabled={@debug_mode or not @can_manage_tournament}
        />
        <input
          id={"score-input-id-#{@match_participant_id}"}
          onClick="this.select();"
          inputmode="numeric"
          class="w-8 h-full p-0 font-normal text-center form-input active:border-primary"
          phx-debounce="700"
          type="text"
          min="0"
          name="score"
          value={@match_participant_score}
          disabled={
            @debug_mode or not @can_manage_tournament or
              not @edit_mode
          }
        />
      </form>
    </div>
    """
  end

  attr(:match, :any, required: true)
  attr(:debug_mode, :boolean, required: true)
  attr(:all_participant_details, :map, required: true)

  defp match_details_modal(assigns) do
    ~H"""
    <div class="relative h-0">
      <.button
        id={"match-details-modal-button-#{@match.id}"}
        phx-click={show_modal("match-details-modal-#{@match.id}")}
        class="absolute -left-5 -top-3 text-primary text-xl bg-blackish hover:bg-grey-light border-primary !py-0 !px-1"
      >
        ℹ
      </.button>
      <.modal_medium
        id={"match-details-modal-#{@match.id}"}
        modal_size="p-8 modal__dialog modal__dialog--medium"
      >
        <:header>
          <h3>
            Round <%= @match.round %>, "<%= humanize(@match.type) %>" match details
          </h3>
        </:header>
        <.copyable_content id={"match_id-#{@match.id}"} content={@match.id} label="Match ID" />
        <.copyable_content
          :for={mp <- @match.participants}
          id={"mp_id-#{mp.id}"}
          content={mp.id}
          label={"Match Participant ID for #{Map.get(@all_participant_details, mp.tournament_participant_id).name}"}
        />
      </.modal_medium>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:content, :string, required: true)
  attr(:label, :string, required: true)

  defp copyable_content(assigns) do
    ~H"""
    <form action="" class="flex items-center mb-10">
      <div>
        <label for="copyable_content">
          <%= @label %>
        </label>
        <input
          id={@id}
          class="mr-10 form-input w-72 max-h-9"
          name="copyable_content"
          type="text"
          value={@content}
          autocomplete="off"
          disabled
          phx-click={
            JS.dispatch("grilla:clipcopyinput", to: "##{@id}")
            |> JS.add_class("border-primary text-primary shadow-primary", to: "##{@id}")
          }
        />
      </div>
      <.button
        id={"copyable-content-button-#{@id}"}
        button_type={:primary}
        class="py-1"
        type="button"
        phx-click={
          JS.dispatch("grilla:clipcopyinput", to: "##{@id}")
          |> JS.add_class("border-primary text-primary shadow-primary", to: "##{@id}")
        }
      >
        Copy
      </.button>
    </form>
    """
  end
end
