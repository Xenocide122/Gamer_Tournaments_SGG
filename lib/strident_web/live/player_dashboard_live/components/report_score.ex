defmodule StridentWeb.PlayerDashboardLive.Components.ReportScore do
  @moduledoc false
  use StridentWeb, :live_component
  require Logger
  alias Ecto.Changeset
  alias Strident.MatchReports
  alias Strident.MatchReports.MatchReport
  alias Strident.Repo
  alias Strident.Stages
  alias Strident.TournamentParticipants

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{tournament: tournament, participant: participant, next_match: next_match} = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:tournament, tournament)
    |> assign(:participant, participant)
    |> assign(:next_match, Repo.preload(next_match, participants: :tournament_participant))
    |> assign_my_match_participant()
    |> assign_allow_reporting()
    |> assign_already_finished()
    |> assign_match_report_changeset()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("report-change-score", %{"report" => reported_score}, socket) do
    %{
      assigns: %{
        current_user: %{id: reported_by_user_id},
        my_match_participant: match_participant,
        next_match: match
      }
    } = socket

    socket
    |> assign(
      :changeset,
      MatchReports.change_match_report(%MatchReport{}, %{
        reported_by_user_id: reported_by_user_id,
        match_id: match.id,
        match_participant_id: match_participant.id,
        reported_score: reported_score
      })
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("report-change-score", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("report-score", params, socket) do
    %{
      assigns: %{
        current_user: %{id: reported_by_user_id},
        my_match_participant: match_participant,
        next_match: match
      }
    } = socket

    %{"report" => reported_score} = params

    case MatchReports.create_match_report_and_maybe_update_match_score(%{
           match_id: match.id,
           match_participant_id: match_participant.id,
           reported_by_user_id: reported_by_user_id,
           reported_score: reported_score
         }) do
      {:ok, %{match_report: match_report}} ->
        socket
        |> track_segment_event("Match Score Reported", %{
          match_id: match.id,
          match_participant_id: match_participant.id,
          reported_by_user_id: reported_by_user_id
        })
        |> assign(:already_reported?, true)
        |> assign(:changeset, MatchReports.change_match_report(match_report))

      _anything_else ->
        put_flash(socket, :error, "Error while reporting match score!")
    end
    |> then(&{:noreply, &1})
  end

  defp assign_allow_reporting(socket) do
    allow_reporting =
      case socket.assigns.next_match do
        %{stage_id: stage_id} ->
          stage = Enum.find(socket.assigns.tournament.stages, &(&1.id == stage_id))
          Stages.get_settings_value(stage.settings, :participant_can_report_scores, true)

        nil ->
          true
      end

    assign(socket, :allow_reporting?, allow_reporting)
  end

  defp assign_already_finished(socket) do
    %{next_match: next_match, allow_reporting?: allow_reporting} = socket.assigns

    already_finished =
      !!allow_reporting and !!next_match and Enum.any?(next_match.participants, &(&1.rank == 0))

    assign(socket, :already_finished?, already_finished)
  end

  defp assign_my_match_participant(%{assigns: %{next_match: nil}} = socket),
    do: assign(socket, :my_match_participant, nil)

  defp assign_my_match_participant(socket) do
    %{assigns: %{next_match: match, participant: participant}} = socket

    match.participants
    |> Enum.find(&(&1.tournament_participant_id == participant.id))
    |> then(&assign(socket, :my_match_participant, &1))
  end

  defp assign_match_report_changeset(%{assigns: %{next_match: nil}} = socket) do
    reported_by_user_id = get_reported_by_user_id(socket)
    attrs = %{reported_by_user_id: reported_by_user_id}
    changeset = MatchReports.change_match_report(%MatchReport{}, attrs)

    socket
    |> assign(:already_reported?, false)
    |> assign(:changeset, changeset)
  end

  defp assign_match_report_changeset(socket) do
    %{assigns: %{next_match: match, my_match_participant: match_participant}} = socket
    reported_by_user_id = get_reported_by_user_id(socket)
    attrs = %{reported_by_user_id: reported_by_user_id}

    case MatchReports.get_match_report(match.id, match_participant.id) do
      nil ->
        changeset = MatchReports.change_match_report(%MatchReport{}, attrs)

        socket
        |> assign(:already_reported?, false)
        |> assign(:changeset, changeset)

      match_report ->
        changeset = MatchReports.change_match_report(match_report, attrs)

        socket
        |> assign(:already_reported?, true)
        |> assign(:changeset, changeset)
    end
  end

  defp get_reported_by_user_id(socket) do
    case socket.assigns do
      %{current_user: %{id: reported_by_user_id}} -> reported_by_user_id
      _ -> nil
    end
  end
end
