defmodule StridentWeb.TournamentBracketAndSeedingLive.WebView do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.MatchParticipantSwitching
  alias Strident.NotifyClient
  alias Strident.Stages
  alias Strident.Tournaments
  alias StridentWeb.TournamentManagment.Setup
  alias StridentWeb.TournamentPageLive.AssignTransformer
  alias StridentWeb.TournamentPageLive.Components.MatchesGraph

  on_mount({Setup, :full})
  on_mount({StridentWeb.InitAssigns, :default})

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> close_confirmation()
    |> assign(:team_site, :bracket_and_seeding)
    |> assign(:stage_round_filter, Stages.build_stage_round_filter_from_params!(nil, nil))
    |> assign(:stage, Enum.at(socket.assigns.tournament.stages, 0))
    |> subscribe_to_tournament_updates()
    |> assign_show_restart_tournament_button()
    |> then(&{:ok, &1, layout: false})
  end

  @impl true
  def handle_params(params, _session, %{assigns: %{tournament: tournament}} = socket) do
    with {:ok, stage_round_filter} <-
           Stages.build_stage_round_filter_from_params(
             Map.get(params, "stage"),
             Map.get(params, "round")
           ),
         stage when stage != nil <-
           Enum.find(tournament.stages, &(&1.type == stage_round_filter.stage_type)),
         true <- does_stage_match_have_type?(stage, stage_round_filter),
         true <- does_stage_match_have_round?(stage, stage_round_filter) do
      socket
      |> assign(:stage_round_filter, stage_round_filter)
      |> assign(:stage, stage)
      |> then(&{:noreply, &1})
    else
      nil ->
        {:ok, default_stage_filter} = Stages.build_stage_round_filter_from_params(nil, nil)
        stage = Stages.get_first_stage(tournament.stages)

        socket
        |> assign(:stage_round_filter, %{default_stage_filter | stage_type: Map.get(stage, :type)})
        |> assign(:stage, stage)
        |> then(&{:noreply, &1})

      _ ->
        # TODO check all occurrences of tournament_bracket_and_seeding_path, :index :bracket_and_seeding
        socket
        |> put_flash(:error, "Can't open this stage round")
        |> push_patch(
          to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
        )
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("close-modal", _, socket) do
    send(self(), :close_modal)
    {:noreply, socket}
  end

  @impl true
  def handle_event("click-match-participant", _unsigned_params, socket) do
    {:noreply, socket}
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
    mp_id = if mp_id in ["null", ""], do: nil, else: mp_id
    new_tp_id = if new_tp_id in ["null", ""], do: nil, else: new_tp_id

    socket
    |> switch_first_round_match_participant(match_id, mp_id, new_tp_id)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(:close_modal, socket) do
    send_update(StridentWeb.TournamentBracketAndSeedingLive.Components.Matches,
      id: "matches-in-stage-round",
      show_match_modal: false
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated_match, match}, %{assigns: %{stage: %{id: stage_id}}} = socket) do
    %{id: match_id, starts_at: time} = match

    matches =
      Enum.map(socket.assigns.stage.matches, fn
        %{id: id} = match when id == match_id -> %{match | starts_at: time}
        match -> match
      end)

    socket
    |> update(:stage, &%{&1 | matches: matches})
    |> update(:tournament, fn tournament ->
      stages =
        tournament.stages
        |> Enum.map(fn
          %{id: id} = stage when id == stage_id ->
            %{stage | matches: matches}

          stage ->
            stage
        end)

      %{tournament | stages: stages}
    end)
    |> tap(fn _ -> send(self(), :close_modal) end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:match_winner, details}, socket) do
    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_match_winner(tournament, details)
    end)
    |> push_match_winner_event_to_matches_graph(details)
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
    socket
    |> update(:tournament, fn tournament ->
      AssignTransformer.transform_tournament_assign_with_deleted_match_participant(
        tournament,
        details
      )
    end)
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
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:tournament_matches_regenerated, details}, socket) do
    %{tournament_id: tournament_id} = details
    %{tournament: tournament} = socket.assigns

    if tournament.id == tournament_id do
      {:cont, socket} =
        socket
        |> Setup.do_on_mount(tournament.slug, Setup.tournament_full_preloads())

      socket
      |> put_flash(:info, "Tournament regenerated, syncing view...")
      |> then(&{:noreply, &1})
    else
      {:noreply, socket}
    end
  end

  defp assign_show_restart_tournament_button(socket) do
    %{assigns: %{tournament: tournament}} = socket

    show_restart_tournament_button =
      tournament.status == [:in_progress] and Enum.any?(tournament.participants)

    assign(socket, :show_restart_tournament_button, show_restart_tournament_button)
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
          |> put_flash(:info, "Switched match participants!")

        {:error, _, error, _} when is_binary(error) ->
          Logger.error("Error switching match participants. #{error}")

        {:error, _, _, _} = error ->
          Logger.error("Error switching match participants. #{inspect(error, pretty: true)}")

          put_flash(
            socket,
            :error,
            "Unable to switch participants. Please reload the page and try again."
          )
      end
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  @spec maybe_push_created_mp(Socket.t(), map()) :: Socket.t()
  defp maybe_push_created_mp(socket, results) do
    case Map.get(results, :created_mp) do
      %MatchParticipant{match: %{type: match_type}} = mp
      when match_type in [:upper, :lower, :standard] ->
        push_event(socket, "created_match_participant", %{
          mp_id: mp.id,
          tp_id: mp.tournament_participant_id,
          match_id: mp.match.id,
          group: mp.match.group,
          match_type: mp.match.type
        })

      _ ->
        socket
    end
  end

  @spec maybe_push_updated_other_mp(Socket.t(), map()) :: Socket.t()
  defp maybe_push_updated_other_mp(socket, results) do
    case Map.get(results, :updated_other_mp) do
      %MatchParticipant{match: %{type: match_type}} = mp
      when match_type in [:upper, :lower, :standard] ->
        push_event(socket, "updated_other_match_participant", %{
          mp_id: mp.id,
          tp_id: mp.tournament_participant_id,
          match_id: mp.match.id,
          group: mp.match.group,
          match_type: mp.match.type
        })

      _ ->
        socket
    end
  end

  @spec maybe_push_deleted_mp(Socket.t(), map()) :: Socket.t()
  defp maybe_push_deleted_mp(socket, results) do
    case Map.get(results, :deleted_mp) do
      %MatchParticipant{match: %{type: match_type}} = mp
      when match_type in [:upper, :lower, :standard] ->
        push_event(socket, "deleted_match_participant", %{
          mp_id: mp.id,
          match_id: mp.match.id,
          group: mp.match.group,
          match_type: mp.match.type
        })

      %MatchParticipant{match: %{type: match_type}} = mp when match_type in [:pool, :swiss] ->
        push_event(socket, "reset_null_switcher_value", %{group: mp.match.group, mp_id: mp.id})

      _ ->
        socket
    end
  end

  defp push_match_winner_event_to_matches_graph(socket, details) do
    details.child_matches
    |> Enum.filter(&(&1.type in [:standard, :upper, :lower]))
    |> Enum.reduce(socket, fn child_match, socket ->
      updated_child_match =
        details.child_participants
        |> Enum.filter(&(&1.match_id == child_match.id))
        |> Enum.reduce(child_match, fn new_participant, child_match ->
          %{child_match | participants: child_match.participants ++ [new_participant]}
        end)

      socket
      |> push_event("update_node", %{
        stage_id: details.stage_id,
        match_id: child_match.id,
        match_type: child_match.type,
        stage_round: details.stage_round,
        match_round: child_match.round,
        starts_at: child_match.starts_at,
        mp_details: MatchesGraph.build_mp_details(updated_child_match),
        tournament_status: socket.assigns.tournament.status
      })
      |> push_event("update_edge", %{
        edge: %{
          id: MatchesGraph.edge_id(details.match_id, child_match.id),
          source: details.match_id,
          target: child_match.id
        },
        parent_has_winner: true,
        child_has_winner: false
      })
    end)
    |> push_event("update_node", %{
      stage_id: details.stage_id,
      match_id: details.match_id,
      match_type: details.match_type,
      stage_round: details.stage_round,
      match_round: details.match_round,
      starts_at: details.match_starts_at,
      mp_details:
        MatchesGraph.build_mp_details(%{
          participants: details.updated_winners ++ details.updated_losers
        }),
      tournament_status: socket.assigns.tournament.status
    })
    |> then(fn socket ->
      Enum.reduce(details.parent_ids, socket, fn parent_id, socket ->
        push_event(socket, "update_edge", %{
          edge: %{
            id: MatchesGraph.edge_id(parent_id, details.match_id),
            source: parent_id,
            target: details.match_id
          },
          parent_has_winner: true,
          child_has_winner: true
        })
      end)
    end)
  end

  defp does_stage_match_have_round?(nil, %{stage_match_round: nil}) do
    true
  end

  defp does_stage_match_have_round?(_stage, %{stage_match_round: nil}) do
    true
  end

  defp does_stage_match_have_round?(stage, %{stage_match_round: stage_round}) do
    Enum.reduce_while(stage.matches, false, fn
      %{round: ^stage_round}, _ -> {:halt, true}
      _match, no_valid_round -> {:cont, no_valid_round}
    end)
  end

  def does_stage_match_have_type?(nil, %{stage_match_type: nil}) do
    true
  end

  def does_stage_match_have_type?(_stage, %{stage_match_type: nil}) do
    true
  end

  def does_stage_match_have_type?(stage, %{stage_match_type: stage_type}) do
    Enum.reduce_while(stage.matches, false, fn
      %{type: ^stage_type}, _ -> {:halt, true}
      _match, no_valid_round -> {:cont, no_valid_round}
    end)
  end
end
