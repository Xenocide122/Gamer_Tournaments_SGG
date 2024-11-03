defmodule StridentWeb.TournamentPageLive.Components.PoolStage do
  @moduledoc """
  Displays comrehensive info on a "pool" type stage,
  e.g. Round Robin.

  If current user has the necessary permission
  (ATOW - if they are "staff", i.e. `is_staff == true`)
  then they can update scores and mark winners.
  """
  use StridentWeb, :live_component
  alias Strident.Matches
  alias Strident.Matches.Match
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.Stages.Stage
  alias Strident.Stages.StageParticipant
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Strident.Tournaments.TournamentParticipant
  alias StridentWeb.TournamentPageLive.Components.PoolStageMatches
  alias Phoenix.LiveView.Socket

  @type participant_details :: %{
          TournamentParticipant.id() => %{
            :name => String.t() | nil,
            :logo_url => String.t() | nil
          }
        }
  @type per_participant_results :: %{
          :sp_id => nil | Strident.id(),
          :placing => nil | non_neg_integer(),
          :played => non_neg_integer(),
          :won => non_neg_integer(),
          :lost => non_neg_integer(),
          :tied => non_neg_integer(),
          optional(:first_round_match_id) => nil | Strident.id(),
          optional(:first_round_mp_id) => nil | Strident.id(),
          :advance => nil | :upper | :lower
        }
  @type participant_results :: %{
          Strident.id() => per_participant_results()
        }

  @type outcome :: :won | :lost | :tied
  @initial_participant_results %{
    advance: nil,
    sp_id: nil,
    placing: nil,
    played: 0,
    won: 0,
    lost: 0,
    tied: 0,
    first_round_match_id: nil,
    first_round_mp_id: nil
  }

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{
          stage: stage,
          participants: participants,
          tournament_status: tournament_status,
          required_participant_count: required_participant_count,
          tournament: tournament,
          current_user: current_user
        } = assigns,
        socket
      ) do
    required_participant_count = required_participant_count || Enum.count(participants)

    number_of_participants_per_group =
      determine_number_of_participants_per_group(stage, required_participant_count, participants)

    socket
    |> copy_parent_assigns(assigns)
    |> assign(
      :can_manage_tournament,
      Tournaments.can_manage_tournament?(current_user, tournament)
    )
    |> assign(:tournament_id, stage.tournament_id)
    |> assign(:tournament_status, tournament_status)
    |> assign(:stage_id, stage.id)
    |> assign(:stage_type, stage.type)
    |> assign(:stage_status, stage.status)
    |> assign(:stage_round, stage.round)
    |> assign_participant_details(participants)
    |> assign_participant_options()
    |> assign_groups(stage, participants, number_of_participants_per_group)
    |> assign_child_stage_type(stage)
    |> then(&{:ok, &1})
  end

  def assign_child_stage_type(socket, %{children: []}) do
    assign(socket, :child_stage_type, nil)
  end

  def assign_child_stage_type(socket, %{children: [%{type: type}]}) do
    assign(socket, :child_stage_type, type)
  end

  @spec assign_participant_details(Socket.t(), [TournamentParticipant.t()]) :: Socket.t()
  defp assign_participant_details(socket, participants) do
    participants
    |> build_name_and_logo_map(socket.assigns.can_manage_tournament)
    |> then(&assign(socket, :participant_details, &1))
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

  @spec build_name_and_logo_map([TournamentParticipant.t()], boolean()) :: participant_details()
  defp build_name_and_logo_map(participants, show_email) do
    Enum.reduce(participants, %{}, fn participant, name_and_logo_map ->
      name = TournamentParticipants.participant_name(participant, show_email: show_email)
      logo_url = TournamentParticipants.participant_logo_url(participant)
      Map.put(name_and_logo_map, participant.id, %{name: name, logo_url: logo_url})
    end)
  end

  @spec put_placings(participant_results(), [StageParticipant.t()]) :: participant_results()
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

  @spec assign_groups(Socket.t(), Stage.t(), [TournamentParticipant.t()], non_neg_integer()) ::
          Socket.t()
  defp assign_groups(socket, stage, participants, number_of_participants_per_group) do
    stage.matches
    |> Enum.group_by(& &1.group)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce(%{}, fn {group, same_group_matches}, groups ->
      has_first_round_bye_matches = Matches.has_first_round_bye_matches(same_group_matches)

      participant_results =
        same_group_matches
        |> build_participant_results()
        |> put_placings(stage.participants)
        |> put_advance_to_next_stage(stage)

      Map.put(groups, group, %{
        matches: same_group_matches,
        has_first_round_bye_matches: has_first_round_bye_matches,
        participant_results: participant_results
      })
    end)
    |> put_ghost_participant_details(participants, number_of_participants_per_group)
    |> then(&assign(socket, :groups, &1))
  end

  defp put_advance_to_next_stage(participants, stage) do
    if Enum.any?(stage.children) and stage.settings != [] do
      advance_settings = transpose_settings(stage)
      participants_count = Enum.count(participants)

      needed_matches_played_per_participant =
        case advance_settings do
          %{number_times_players_meet: number_times_players_meet} ->
            participants_count * number_times_players_meet - 1

          %{number_rounds: number_rounds} ->
            number_rounds
        end

      participants
      |> Enum.map(fn {participant, values} ->
        if needed_matches_played_per_participant == Map.get(values, :played) do
          {participant, advance_participant(advance_settings, values)}
        else
          {participant, Map.put(values, :advance, nil)}
        end
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

  defp transpose_settings(stage) do
    Enum.reduce(stage.settings, %{}, fn
      %{name: key} = setting, settings -> Map.put(settings, key, elem(setting.value, 0))
    end)
  end

  defp put_ghost_participant_details(groups, participants, number_of_participants_per_group) do
    off_track_statuses = Tournaments.off_track_participant_statuses()

    claimed_participant_ids =
      Enum.flat_map(groups, fn {_group_name, %{participant_results: participant_results}} ->
        Map.keys(participant_results)
      end)

    unclaimed_on_track_participants =
      Enum.reject(
        participants,
        &(&1.id in claimed_participant_ids or &1.status in off_track_statuses)
      )

    {filled_groups, _unclaimed_on_track_participants} =
      Enum.map_reduce(groups, unclaimed_on_track_participants, fn
        {group_name, group_details}, unclaimed_on_track_participants ->
          number_of_ghosts =
            number_of_participants_per_group - Enum.count(group_details.participant_results)

          bye_match_ids =
            group_details.participant_results
            |> Map.values()
            |> Enum.map(& &1.first_round_match_id)
            |> Enum.reject(&is_nil/1)
            |> Enum.frequencies()
            |> Enum.filter(&(elem(&1, 1) == 1))
            |> Enum.map(&elem(&1, 0))

          empty_match_ids =
            group_details.matches
            |> Enum.filter(&Enum.empty?(&1.participants))
            |> Enum.map(& &1.id)
            |> Enum.flat_map(&[&1, &1])

          {ghosts, unclaimed_on_track_participants} =
            Enum.split(unclaimed_on_track_participants, number_of_ghosts)

          {filled_participant_results, _bye_match_ids, _empty_match_ids} =
            Enum.reduce(
              ghosts,
              {group_details.participant_results, bye_match_ids, empty_match_ids},
              fn
                ghost, {participant_results, [bye_match_id | bye_match_ids], empty_match_ids} ->
                  @initial_participant_results
                  |> Map.put(:first_round_match_id, bye_match_id)
                  |> then(&Map.put(participant_results, ghost.id, &1))
                  |> then(&{&1, bye_match_ids, empty_match_ids})

                ghost, {participant_results, [], [empty_match_id | empty_match_ids]} ->
                  @initial_participant_results
                  |> Map.put(:first_round_match_id, empty_match_id)
                  |> then(&Map.put(participant_results, ghost.id, &1))
                  |> then(&{&1, [], empty_match_ids})

                _ghost, {participant_results, [], []} ->
                  {participant_results, [], []}
              end
            )

          filled_group_details =
            Map.put(group_details, :participant_results, filled_participant_results)

          {{group_name, filled_group_details}, unclaimed_on_track_participants}
      end)

    filled_groups
  end

  @spec build_participant_results([Match.t()]) :: participant_results()
  defp build_participant_results(matches) do
    Enum.reduce(matches, %{}, &add_match_to_participant_results/2)
  end

  @spec add_match_to_participant_results(Match.t(), participant_results()) ::
          participant_results()
  defp add_match_to_participant_results(match, results) do
    {winners, non_winners} = Enum.split_with(match.participants, &(&1.rank == 0))

    non_winners
    |> Enum.reduce(results, &add_participant_to_results(&1, &2, :lost))
    |> then(fn results ->
      case winners do
        [winner] ->
          add_participant_to_results(winner, results, :won)

        winners ->
          Enum.reduce(winners, results, &add_participant_to_results(&1, &2, :tied))
      end
    end)
    |> then(fn results ->
      if match.round == 0 do
        Enum.reduce(match.participants, results, fn mp, results ->
          Map.update!(
            results,
            mp.tournament_participant_id,
            &Map.merge(&1, %{first_round_match_id: match.id, first_round_mp_id: mp.id})
          )
        end)
      else
        results
      end
    end)
  end

  @spec add_participant_to_results(
          MatchParticipant.t(),
          participant_results(),
          outcome()
        ) ::
          participant_results()
  defp add_participant_to_results(
         %{tournament_participant_id: participant_id, rank: nil},
         results,
         _outcome
       ) do
    Map.put_new(results, participant_id, @initial_participant_results)
  end

  defp add_participant_to_results(%{tournament_participant_id: participant_id}, results, outcome) do
    Map.update(
      results,
      participant_id,
      increment_result(@initial_participant_results, outcome),
      &increment_result(&1, outcome)
    )
  end

  @spec increment_result(per_participant_results(), outcome()) :: per_participant_results()
  defp increment_result(results, outcome) do
    results
    |> Map.update!(:played, &(&1 + 1))
    |> Map.update!(outcome, &(&1 + 1))
  end

  defp determine_number_of_participants_per_group(
         %{type: :swiss},
         _required_participant_count,
         participants
       ) do
    Enum.count(participants)
  end

  # This one returns number of participants currently in the group,
  # so two per group
  defp determine_number_of_participants_per_group(
         %{type: :round_robin} = stage,
         required_participant_count,
         _participants
       ) do
    case transpose_settings(stage) do
      %{number_groups: number_of_groups} when is_integer(number_of_groups) ->
        ceil(required_participant_count / number_of_groups)

      _ ->
        stage.matches
        |> Enum.map(& &1.group)
        |> Enum.uniq()
        |> Enum.count()
        |> then(fn
          0 -> 0
          number_of_groups -> ceil(required_participant_count / number_of_groups)
        end)
    end
  end

  defp advance_border_class(:upper) do
    "after:absolute after:inset-y-0 after:w-0.5 after:bg-primary after:shadow-primary"
  end

  defp advance_border_class(:lower) do
    "after:absolute after:inset-y-0 after:w-0.5 after:bg-grilla-pink after:shadow-grilla-pink"
  end

  defp advance_border_class(_) do
    ""
  end
end
