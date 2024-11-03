defmodule StridentWeb.TournamentBracketAndSeedingLive do
  @moduledoc false
  use StridentWeb, :live_component

  require Logger

  alias Strident.Stages
  alias Strident.Tournaments

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    %{
      can_manage_tournament: can_manage_tournament,
      current_user: current_user,
      debug_mode: debug_mode,
      tournament: tournament
    } = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      can_manage_tournament: can_manage_tournament,
      current_user: current_user,
      debug_mode: debug_mode,
      tournament: tournament
    })
    |> assign(:team_site, :bracket_and_seeding)
    |> assign(:stage_round_filter, Stages.build_stage_round_filter_from_params!(nil, nil))
    |> assign(:stage, Enum.at(tournament.stages, 0))
    |> assign_show_restart_tournament_button()
    |> then(&{:ok, &1})
  end

  def handle_params(params, _session, socket) do
    %{tournament: tournament} = socket.assigns

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
    else
      nil ->
        {:ok, default_stage_filter} = Stages.build_stage_round_filter_from_params(nil, nil)
        stage = Stages.get_first_stage(tournament.stages)

        stage_round_filter =
          if stage do
            Map.put(default_stage_filter, :stage_type, Map.get(stage, :type))
          else
            default_stage_filter
          end

        socket
        |> assign(:stage_round_filter, stage_round_filter)
        |> assign(:stage, stage)

      _ ->
        socket
        |> put_flash(:error, "Can't open this stage round")
        |> push_patch(
          to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
        )
    end
  end

  defp assign_show_restart_tournament_button(socket) do
    %{tournament: tournament, can_manage_tournament: can_manage_tournament} = socket.assigns

    # show_restart_tournament_button =
    #   can_manage_tournament &&
    #     tournament.status == :in_progress and
    #     Enum.any?(tournament.participants) and
    #     Enum.all?(tournament.stages, &(&1.status in [:scheduled, :in_progress]))

    show_restart_tournament_button =
      can_manage_tournament &&
        tournament.status in [
          :registrations_open,
          :registrations_closed,
          :in_progress,
          :under_review
        ] and
        Enum.count(tournament.participants) > 3

    assign(socket, :show_restart_tournament_button, show_restart_tournament_button)
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
end
