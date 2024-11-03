defmodule StridentWeb.TournamentPageLive.Components.MatchesGraph do
  @moduledoc false
  use StridentWeb, :live_component
  require Logger
  alias Strident.Accounts
  alias Strident.BijectiveHexavigesimal
  alias Strident.DoubleElimination
  alias Strident.Extension.NaiveDateTime
  alias Strident.Matches
  alias Strident.Matches.Match
  alias Strident.MatchesGeneration
  alias Strident.MatchParticipants
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Strident.Tournaments.TournamentParticipant
  alias Strident.Winners
  alias StridentWeb.TournamentPageLive.Components.MarkMatchWinnerConfirmationMessage
  alias Phoenix.LiveView.Socket

  @x_multiplier 320
  @x_offset 20
  @y_offset 10
  @width 260

  defp height(_), do: 74
  defp y_multiplier(:lower, match_round), do: y_multiplier(:upper, div(match_round, 2))
  defp y_multiplier(_, match_round), do: Math.pow(2, match_round) * 90
  defp y_round_multiplier(match_type, match_round), do: y_multiplier(match_type, match_round) / 2

  @impl true
  def mount(socket) do
    socket
    |> close_confirmation()
    |> show_loading_message()
    |> then(&{:ok, &1})
  end

  @impl true
  def update(
        %{stage: stage, tournament_status: tournament_status} = assigns,
        %{assigns: %{is_not_first_update: true}} = socket
      ) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign_has_first_round_bye_matches(stage.matches)
    |> assign(%{tournament_status: tournament_status})
    |> assign(%{tournament_id: stage.tournament_id})
    |> assign_match_details(stage.matches)
    |> then(&{:ok, &1})
  end

  def update(
        %{
          stage: stage,
          participants: participants,
          tournament_status: tournament_status,
          current_user: current_user,
          tournament: tournament
        } = assigns,
        socket
      ) do
    debug_mode = Map.get(assigns, :debug_mode, false)
    can_manage_tournament = Tournaments.can_manage_tournament?(current_user, tournament)

    enable_seeding =
      stage.round == 0 and
        tournament.status in [:scheduled, :registrations_open, :registrations_closed]

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:debug_mode, debug_mode)
    |> assign(:enable_seeding, enable_seeding)
    |> assign(:show_seeding, false)
    |> assign(:can_manage_tournament, can_manage_tournament)
    |> assign(%{tournament_id: tournament.id})
    |> assign(%{tournament_slug: tournament.slug})
    |> assign(%{tournament_status: tournament_status})
    |> assign(%{stage_id: stage.id})
    |> assign(%{stage_round: stage.round})
    |> assign(%{stage_type: stage.type})
    |> assign(%{stage_status: stage.status})
    |> assign(%{stage_participants: stage.participants})
    |> assign(%{participants: participants})
    |> assign_match_details(stage.matches)
    |> assign_has_first_round_bye_matches(stage.matches)
    |> start_building_graph()
    |> assign(:is_not_first_update, true)
    |> then(&{:ok, &1})
  end

  @spec assign_match_details(Socket.t(), [Match.t()]) :: Socket.t()
  defp assign_match_details(socket, matches) do
    type_grouped_matches = Enum.group_by(matches, & &1.type)
    upper_matches = Map.get(type_grouped_matches, :upper, [])

    upper_match_tp_ids =
      upper_matches
      |> Enum.flat_map(& &1.participants)
      |> Enum.map(& &1.tournament_participant_id)

    {number_of_initial_matches_by_type, max_rounds_by_type,
     number_of_initial_participants_by_type} =
      Enum.reduce(type_grouped_matches, {%{}, %{}, %{}}, fn {type, matches},
                                                            {matches_acc, rounds_acc,
                                                             participants_acc} ->
        initial_matches = Enum.filter(matches, &(&1.round == 0))
        number_of_initial_matches = Enum.count(initial_matches)

        number_of_participants =
          Enum.reduce(initial_matches, 0, fn match, total ->
            total +
              Enum.count(
                match.participants,
                &(&1.tournament_participant_id not in upper_match_tp_ids or match.type != :lower)
              )
          end)

        max_rounds = Enum.max_by(matches, & &1.round).round

        {Map.put(matches_acc, type, number_of_initial_matches),
         Map.put(rounds_acc, type, max_rounds),
         Map.put(participants_acc, type, number_of_participants)}
      end)

    first_lower_round_will_converge_edges =
      case number_of_initial_participants_by_type do
        %{upper: number_participants_upper_round_0, lower: number_participants_lower_round_0} ->
          lower_round_where_first_round_losers_drop =
            DoubleElimination.lower_round_where_first_round_losers_drop(
              number_participants_upper_round_0,
              number_participants_lower_round_0
            )

          MatchesGeneration.first_lower_round_will_converge_edges(
            lower_round_where_first_round_losers_drop,
            number_participants_lower_round_0
          )

        _ ->
          false
      end

    match_details =
      type_grouped_matches
      |> Enum.map(fn {type, matches} ->
        {type, group_by_round_sorted_last_round_to_first(matches)}
      end)
      |> build_match_details_with_parent_details(matches)
      |> add_tbd_participants()

    socket
    |> assign(:max_rounds_by_type, max_rounds_by_type)
    |> assign(:number_of_initial_matches_by_type, number_of_initial_matches_by_type)
    |> assign(:match_details, match_details)
    |> assign(:first_lower_round_will_converge_edges, first_lower_round_will_converge_edges)
  end

  defp start_building_graph(socket) do
    all_participant_details =
      socket.assigns.participants
      |> Enum.map(
        &%{
          id: &1.id,
          logo_url: TournamentParticipants.participant_logo_url(&1),
          name:
            TournamentParticipants.participant_name(&1,
              show_email: socket.assigns.can_manage_tournament
            ),
          seed_index: &1.seed_index,
          status: &1.status
        }
      )
      |> Enum.sort_by(& &1.name)
      |> then(&[%{id: nil, logo_url: Accounts.avatar_url(), name: nil} | &1])

    socket
    |> assign(%{all_participant_details: all_participant_details})
    |> push_event("start_building_graph", %{all_participant_details: all_participant_details})
  end

  @impl true
  def handle_event(
        "start_building_graph",
        _payload,
        %{assigns: %{participants: participants}} = socket
      ) do
    socket
    |> add_nodes_and_edges(participants)
    |> hide_loading_message()
    |> zoom_to_fit()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("zoom-to-fit", _params, socket) do
    socket
    |> zoom_to_fit()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("zoom-in", _params, socket) do
    socket
    |> zoom_in()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("zoom-out", _params, socket) do
    socket
    |> zoom_out()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("toggle-show-seeding", _params, socket) do
    socket
    |> assign(:show_seeding, !socket.assigns.show_seeding)
    |> start_building_graph()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("mark-match-winner-clicked", %{"id" => id}, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_message:
        mark_match_winner_confirmation_message(
          socket.assigns.match_details,
          socket.assigns.all_participant_details,
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
    |> close_confirmation()
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
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("set-match-participant-score", %{"id" => id, "score" => score}, socket) do
    socket
    |> set_match_participant_score(id, score)
    |> then(&{:noreply, &1})
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

        _ ->
          put_flash(
            socket,
            :error,
            "Could not update score. Please reload the page and try again."
          )
      end
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  defp mark_match_winner(socket, match_participant_id) do
    if socket.assigns.can_manage_tournament do
      match_participant = MatchParticipants.get_match_participant(match_participant_id)
      Winners.mark_match_winner(match_participant)

      receive do
        {:ok, _details} ->
          socket
          |> track_segment_event("Marked Match Winner", %{
            match_participant_id: match_participant.id,
            match_id: match_participant.match_id,
            tournament_id: socket.assigns.tournament_id
          })
          |> put_flash(:info, "Marked match winner!")

        {:error, error} ->
          put_string_or_changeset_error_in_flash(socket, error)
      end
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  defp reset_match(socket, match_id) do
    if socket.assigns.can_manage_tournament do
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
    match_detail =
      Enum.find(match_details, fn %{mp_details: mp_details} ->
        Enum.any?(mp_details, &(&1.id == match_winner_id))
      end)

    {winner_name, scores} =
      Enum.reduce(match_detail.mp_details, {nil, []}, fn
        %{id: mp_id} = mp_detail, {winner_name, scores_list} ->
          name =
            Enum.find(all_participant_details, &(&1.id == mp_detail.tournament_participant_id)).name

          score = Map.get(mp_detail, :score)
          winner_name = if mp_id == match_winner_id, do: name, else: winner_name
          {winner_name, [%{name: name, score: score} | scores_list]}
      end)

    MarkMatchWinnerConfirmationMessage.mark_match_winner_confirmation_message(%{
      winner_name: winner_name,
      scores: scores
    })
  end

  @spec assign_has_first_round_bye_matches(Socket.t(), [Match.t()]) :: Socket.t()
  def assign_has_first_round_bye_matches(socket, matches) do
    matches
    |> Matches.has_first_round_bye_matches()
    |> then(&assign(socket, %{has_first_round_bye_matches: &1}))
  end

  defp show_loading_message(socket) do
    push_event(socket, "show_loading_message", %{image_url: logo_url()})
  end

  defp hide_loading_message(socket) do
    push_event(socket, "hide_loading_message", %{})
  end

  defp zoom_in(socket) do
    push_event(socket, "zoom-in", %{})
  end

  defp zoom_out(socket) do
    push_event(socket, "zoom-out", %{})
  end

  defp zoom_to_fit(socket) do
    push_event(socket, "zoom-to-fit", %{})
  end

  @spec add_nodes_and_edges(Socket.t(), [TournamentParticipant.t()]) :: Socket.t()
  defp add_nodes_and_edges(socket, participants) do
    socket.assigns.match_details
    |> Enum.map_reduce(socket, fn match_detail, socket ->
      {match_detail, add_node(socket, match_detail, participants)}
    end)
    |> then(fn {match_details, socket} ->
      Enum.reduce(match_details, socket, fn match_detail, socket ->
        maybe_add_edges_to_parent(socket, match_detail, match_details)
      end)
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
    # for some reason this works better
    Enum.reverse(siblings)
  end

  defp sort_by_child_sorting(siblings, [{_parent_round, sorted_children} | _]) do
    Enum.sort_by(siblings, fn
      %{id: id} ->
        Enum.find_index(sorted_children, fn %{parents: parents} ->
          Enum.any?(parents, &(&1.id == id))
        end)

      _ ->
        nil
    end)
  end

  @type mp_detail() :: %{
          required(:id) => MatchParticipant.id(),
          required(:rank) => MatchParticipant.rank(),
          required(:score) => MatchParticipant.score(),
          required(:tournament_participant_id) => TournamentParticipant.id()
        }
  @type parent_match_detail() :: %{
          required(:id) => Match.id(),
          required(:mp_tp_ids) => [TournamentParticipant.id()],
          required(:y_index) => non_neg_integer()
        }
  @type match_detail() :: %{
          required(:id) => Match.id(),
          required(:label) => String.t(),
          required(:mp_details) => [mp_detail()],
          required(:type) => Match.match_type(),
          required(:round) => Match.round(),
          required(:starts_at) => NaiveDateTime.t() | nil,
          required(:y_index) => non_neg_integer(),
          required(:parent_ids) => [Match.id()]
        }
  @type match_detail_with_parent_details() :: %{
          required(:id) => Match.id(),
          required(:type) => Match.match_type(),
          required(:round) => Match.round(),
          required(:starts_at) => NaiveDateTime.t() | nil,
          required(:y_index) => non_neg_integer(),
          required(:parent_ids) => [Match.id()],
          required(:mp_details) => [mp_detail()],
          required(:label) => String.t(),
          required(:parent_details) => [parent_match_detail()]
        }
  @spec build_match_details_with_parent_details([{Matches.match_type(), [sibling_matches()]}], [
          Match.t()
        ]) ::
          [
            match_detail_with_parent_details()
          ]
  defp build_match_details_with_parent_details(type_and_round_grouped_matches, all_matches) do
    type_and_round_grouped_matches
    |> build_match_details(all_matches)
    |> put_parent_details_on_match_details()
  end

  @spec build_match_details([{Matches.match_type(), [sibling_matches()]}], [Match.t()]) :: [
          match_detail()
        ]
  defp build_match_details(type_and_round_grouped_matches, all_matches) do
    Enum.flat_map(type_and_round_grouped_matches, fn {_type, same_type_matches} ->
      matches_with_y_index =
        Enum.flat_map(same_type_matches, fn {_round, same_round_matches} ->
          Enum.with_index(same_round_matches)
        end)

      matches_with_y_index_and_labels = Enum.with_index(matches_with_y_index)

      Enum.map(matches_with_y_index_and_labels, fn {{match, y_index}, label_index} ->
        mp_details = build_mp_details(match)

        has_winner = Enum.any?(mp_details, &(&1.rank == 0))

        has_finished_child_match = has_finished_child_match(match, all_matches)

        %{
          id: match.id,
          type: match.type,
          round: match.round,
          starts_at: match.starts_at,
          y_index: y_index,
          parent_ids: Enum.map(match.parent_edges, & &1.parent_id),
          mp_details: mp_details,
          is_resettable: has_winner and not has_finished_child_match,
          label: BijectiveHexavigesimal.to_az_string(label_index)
        }
      end)
    end)
  end

  @spec has_finished_child_match(Match.t(), [Match.t()]) :: boolean()
  defp has_finished_child_match(match, all_matches) do
    Enum.any?(match.child_edges, fn %{child_id: child_match_id} ->
      %{participants: child_mps} = Enum.find(all_matches, &(&1.id == child_match_id))
      Enum.any?(child_mps, &(&1.rank == 0))
    end)
  end

  @spec put_parent_details_on_match_details([match_detail()]) :: [
          match_detail_with_parent_details()
        ]
  defp put_parent_details_on_match_details(match_details) do
    Enum.map(match_details, &put_parent_details_on_match_detail(&1, match_details))
  end

  @spec put_parent_details_on_match_detail(match_detail(), [match_detail()]) ::
          match_detail_with_parent_details()
  defp put_parent_details_on_match_detail(match_detail, match_details) do
    parent_details = build_parent_details(match_detail, match_details)

    match_detail
    |> Map.put(:parent_details, parent_details)
    |> sort_mp_details_by_parent_y_indexes(parent_details)
  end

  @spec build_parent_details(match_detail(), [match_detail()]) :: [parent_match_detail()]
  defp build_parent_details(match_detail, match_details) do
    Enum.reduce(match_detail.parent_ids, [], fn parent_id, acc ->
      case Enum.find(match_details, &(&1.id == parent_id)) do
        nil ->
          acc

        parent ->
          parent_mp_tp_ids = Enum.map(parent.mp_details, & &1.tournament_participant_id)
          [%{id: parent_id, mp_tp_ids: parent_mp_tp_ids, y_index: parent.y_index} | acc]
      end
    end)
  end

  @spec sort_mp_details_by_parent_y_indexes(match_detail_with_parent_details(), [
          parent_match_detail()
        ]) :: match_detail_with_parent_details()
  defp sort_mp_details_by_parent_y_indexes(
         %{mp_details: mp_details} = match_detail,
         parent_details
       ) do
    sorted_mp_details = sort_mps_by_parent_y_indexes(mp_details, parent_details)
    Map.put(match_detail, :mp_details, sorted_mp_details)
  end

  @spec sort_mps_by_parent_y_indexes([mp_detail()], [parent_match_detail()]) :: [mp_detail()]
  defp sort_mps_by_parent_y_indexes(mp_details, parent_details) do
    Enum.sort_by(mp_details, fn mp_detail ->
      parent_y_index(mp_detail, parent_details)
    end)
  end

  @spec parent_y_index(mp_detail(), [parent_match_detail()]) :: non_neg_integer()
  defp parent_y_index(mp_detail, parent_details) do
    case Enum.find(parent_details, &(mp_detail.tournament_participant_id in &1.mp_tp_ids)) do
      nil -> 0
      %{y_index: y_index} -> y_index
    end
  end

  defp maybe_add_edges_to_parent(socket, match_detail, all_matches) do
    Enum.reduce(match_detail.parent_ids, socket, fn parent_id, socket ->
      parent_match = Enum.find(all_matches, &(&1.id == parent_id))

      cond do
        socket.assigns.debug_mode ->
          add_edges_to_parent(socket, match_detail, parent_match)

        parent_match == nil ->
          socket

        parent_match.type == :upper and match_detail.type == :lower ->
          socket

        parent_match.type == :lower and match_detail.type == :upper ->
          socket

        match_detail.round == 4 ->
          socket

        true ->
          add_edges_to_parent(socket, match_detail, parent_match)
      end
    end)
  end

  defp add_edges_to_parent(socket, match_detail, parent_match) do
    parent_has_winner = Enum.any?(parent_match.mp_details, &(&1.rank == 0))
    child_has_winner = Enum.any?(match_detail.mp_details, &(&1.rank == 0))

    add_edge(
      socket,
      parent_match.id,
      match_detail.id,
      parent_has_winner,
      child_has_winner
    )
  end

  defp add_node(
         %{assigns: %{stage_type: :single_elimination}} = socket,
         %{type: :standard} = match_detail,
         participants
       ) do
    needs_blocks = socket.assigns.number_of_initial_matches_by_type.standard > 8
    is_middle = match_detail.round > 3
    is_final_round = match_detail.round == socket.assigns.max_rounds_by_type.standard

    x_tightener =
      cond do
        needs_blocks and match_detail.round == 2 -> div(match_detail.round * @x_multiplier, 4)
        needs_blocks and match_detail.round == 3 -> div(match_detail.round * @x_multiplier, 3)
        true -> 0
      end

    switch_side_every =
      determine_switch_side_every(
        is_middle,
        socket.assigns.max_rounds_by_type,
        match_detail.round
      )

    side = determine_side(match_detail.y_index, switch_side_every)

    x =
      calculate_x_coordinate(
        match_detail,
        x_tightener,
        socket.assigns.max_rounds_by_type,
        side,
        is_middle
      )

    y =
      calculate_y_coordinate(
        match_detail,
        socket.assigns.number_of_initial_matches_by_type.standard,
        match_detail.y_index,
        switch_side_every,
        is_middle
      )

    socket
    |> push_add_node_event(match_detail, x, y)
    |> then(fn socket ->
      if is_middle and is_final_round do
        socket
        |> add_logo_node(x, y)
        |> then(fn socket ->
          if Enum.any?(participants, &(&1.rank == 0)) do
            winner_details = Enum.find(match_detail.mp_details, &(&1.rank == 0))
            add_final_winner(socket, x, y, winner_details)
          else
            socket
          end
        end)
      else
        socket
      end
    end)
  end

  defp add_node(
         %{assigns: %{stage_type: :double_elimination}} = socket,
         match_detail,
         _participants
       ) do
    x = calculate_x_coordinate(match_detail, socket.assigns.number_of_initial_matches_by_type)

    y =
      calculate_y_coordinate(
        match_detail,
        socket.assigns.number_of_initial_matches_by_type,
        socket.assigns.max_rounds_by_type,
        match_detail.y_index,
        socket.assigns.first_lower_round_will_converge_edges
      )

    socket
    |> push_add_node_event(match_detail, x, y)
    |> then(fn socket ->
      if match_detail.y_index == 0 and match_detail.round == 0 do
        add_bracket_label(socket, match_detail.type, x, y)
      else
        socket
      end
    end)
  end

  defp push_add_node_event(socket, match_detail, x, y) do
    push_event(socket, "add_node", %{
      stage_id: socket.assigns.stage_id,
      match_id: match_detail.id,
      x: x,
      y: y,
      width: @width,
      height: height(match_detail.type),
      match_type: match_detail.type,
      stage_status: socket.assigns.stage_status,
      stage_round: socket.assigns.stage_round,
      match_round: match_detail.round,
      starts_at: match_detail.starts_at,
      mp_details: match_detail.mp_details,
      tournament_status: socket.assigns.tournament_status,
      is_resettable: match_detail.is_resettable,
      match_label: match_detail.label
    })
  end

  @doc """
  The Cell ID of an edge
  """
  @spec edge_id(Match.id(), Match.id()) :: String.t()
  def edge_id(parent_match_id, child_match_id) do
    "#{parent_match_id}_#{child_match_id}"
  end

  defp add_edge(socket, parent_match_id, child_match_id, parent_has_winner, child_has_winner) do
    push_event(socket, "add_edge", %{
      edge: %{
        id: edge_id(parent_match_id, child_match_id),
        source: parent_match_id,
        target: child_match_id
      },
      parent_has_winner: parent_has_winner,
      child_has_winner: child_has_winner
    })
  end

  @spec determine_switch_side_every(
          boolean(),
          %{Matches.match_type() => Match.round()},
          Match.round()
        ) ::
          Match.round()
  defp determine_switch_side_every(is_middle, max_rounds, match_round) do
    if is_middle do
      Math.pow(2, max(max_rounds.standard - match_round - 1, 0))
    else
      Math.pow(2, max(3 - match_round, 0))
    end
  end

  defp determine_side(y_index, switch_side_every) do
    side_binary_indicator = y_index |> div(switch_side_every) |> rem(2)

    case side_binary_indicator do
      0 -> :left
      1 -> :right
    end
  end

  defp calculate_x_coordinate(
         %{type: :standard} = match,
         x_tightener,
         _max_round,
         :left = _side,
         false = _is_middle
       ) do
    match.round * @x_multiplier + @x_offset - x_tightener
  end

  defp calculate_x_coordinate(
         %{type: :standard} = match,
         x_tightener,
         _max_round,
         :right = _side,
         false = _is_middle
       ) do
    (8 - match.round) * @x_multiplier + @x_offset + x_tightener - 2 * @x_multiplier
  end

  defp calculate_x_coordinate(
         %{round: max_round, type: :standard},
         _x_tightener,
         %{standard: max_round} = _max_rounds,
         _side,
         true = _is_middle
       ) do
    3 * @x_multiplier + @x_offset
  end

  defp calculate_x_coordinate(
         %{type: :standard},
         _x_tightener,
         _max_round,
         :left,
         true = _is_middle
       ) do
    2 * @x_multiplier + @x_offset
  end

  defp calculate_x_coordinate(
         %{type: :standard} = _match,
         _x_tightener,
         _max_round,
         :right,
         true = _is_middle
       ) do
    4 * @x_multiplier + @x_offset
  end

  defp calculate_x_coordinate(
         %{type: :upper} = match,
         %{upper: number_of_initial_upper_matches, lower: number_of_initial_lower_matches}
       ) do
    (div(number_of_initial_lower_matches, number_of_initial_upper_matches) + match.round) *
      @x_multiplier + @x_offset
  end

  defp calculate_x_coordinate(%{type: :lower} = match, _) do
    match.round * @x_multiplier + @x_offset
  end

  defp calculate_y_coordinate(
         %{type: :standard} = match,
         _number_of_initial_matches,
         y_index,
         switch_side_every,
         is_middle
       ) do
    side_specific_y_index =
      y_index
      |> div(switch_side_every)
      |> Kernel.+(1)
      |> div(2)
      |> Kernel.*(switch_side_every)
      |> then(&(y_index - &1))

    if is_middle do
      8 * y_multiplier(match.type, 0) + @y_offset
    else
      side_specific_y_index * y_multiplier(match.type, match.round) +
        y_round_multiplier(match.type, match.round) +
        @y_offset
    end
  end

  defp calculate_y_coordinate(
         %{type: :upper, round: round},
         _,
         max_rounds,
         y_index,
         _first_lower_round_will_converge_edges
       ) do
    round = if round == max_rounds.upper, do: round - 1, else: round
    y_index * y_multiplier(:upper, round) + y_round_multiplier(:upper, round) + @y_offset
  end

  defp calculate_y_coordinate(
         %{type: :lower, round: round},
         %{upper: number_of_initial_upper_matches, lower: _number_of_initial_lower_matches},
         _max_rounds,
         y_index,
         first_lower_round_will_converge_edges
       ) do
    lower_bracket_offset = (number_of_initial_upper_matches + 1) * y_multiplier(:upper, 0)
    lower_round_offset = if first_lower_round_will_converge_edges, do: 1, else: 0

    y_index * y_multiplier(:lower, round + lower_round_offset) +
      y_round_multiplier(:lower, round + lower_round_offset) + @y_offset +
      lower_bracket_offset
  end

  @spec build_mp_details(Match.t() | %{participants: [MatchParticipant.t()]}) :: [mp_detail()]
  def build_mp_details(match) do
    Enum.map(match.participants, fn mp ->
      %{
        id: mp.id,
        tournament_participant_id: mp.tournament_participant_id,
        score: mp.score,
        rank: mp.rank
      }
    end)
  end

  @tbd_participant %{
    id: nil,
    tournament_participant_id: nil,
    name: "TBD",
    score: nil,
    rank: nil
  }

  defp add_tbd_participants(match_details) do
    Enum.map(match_details, fn match_detail ->
      unplayed_parent_details =
        Enum.filter(match_details, fn other_match_detail ->
          other_match_detail.id in match_detail.parent_ids and
            not Enum.any?(other_match_detail.mp_details, &(&1.rank == 0))
        end)

      Map.update!(match_detail, :mp_details, fn mp_details ->
        Enum.reduce(unplayed_parent_details, mp_details, fn unplayed_parent_detail, mp_details ->
          if match_detail.type == unplayed_parent_detail.type do
            [@tbd_participant | mp_details]
          else
            name =
              if unplayed_parent_detail.type == :lower do
                "lower bracket winner"
              else
                "loser of #{unplayed_parent_detail.label}"
              end

            [Map.put(@tbd_participant, :name, name) | mp_details]
          end
        end)
      end)
    end)
  end

  defp logo_url, do: safe_static_url("/images/stride-header-footer-logo.png")

  defp add_logo_node(socket, x, y) do
    push_event(socket, "add_logo_node", %{
      x: x,
      y: y - y_multiplier(:standard, 0),
      width: @width,
      height: height(:standard),
      image_url: logo_url()
    })
  end

  defp add_final_winner(socket, x, y, winner_details) do
    push_event(socket, "add_final_winner", %{
      x: x,
      y: y + y_multiplier(:standard, 0),
      width: @width,
      height: height(:standard),
      winner_details: winner_details
    })
  end

  defp add_bracket_label(socket, match_type, x, y) do
    h = div(height(match_type), 2)

    push_event(socket, "add_bracket_label", %{
      x: x,
      y: y - h,
      width: @width,
      height: h,
      type: match_type
    })
  end
end
