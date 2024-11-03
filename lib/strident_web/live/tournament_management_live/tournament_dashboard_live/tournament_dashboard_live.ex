defmodule StridentWeb.TournamentDashboardLive do
  @moduledoc false
  use StridentWeb, :live_view

  require Logger

  import StridentWeb.TournamentDashboardLive.Components.Widgets

  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.Extension.NaiveDateTime
  alias Strident.Repo
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias Strident.UrlGeneration
  alias StridentWeb.Router.Helpers, as: Routes
  alias StridentWeb.TournamentManagment.Setup
  alias StridentWeb.TournamentParticipants.TournamentParticipantsHelpers
  alias Phoenix.LiveView.JS

  on_mount({Setup, :can_manage_tournament})

  @filter_options [
    %{key: "Sort by Recent", value: :most_recent},
    %{key: "Sort by Oldest", value: :oldest},
    %{key: "Sort by Amount Ascending", value: :amount_asc},
    %{key: "Sort by Amount Descending", value: :amount_desc}
  ]

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    socket
    |> mount_socket_if_can_manage_tournament(slug)
    |> then(&{:ok, &1})
  end

  def handle_event("add-tournament-to-featured", _, socket) do
    tournament = socket.assigns.tournament

    case Tournaments.update_featured(socket.assigns.tournament, %{featured: true}) do
      {:ok, tournament} ->
        socket
        |> assign(tournament: Tournaments.get_tournament!(tournament.id))
        |> then(&{:noreply, &1})

      {:error, msg} ->
        Logger.error(:error, "Failed to add #{tournament.title} from the featured list, #{msg}")

        socket
        |> put_flash(:error, msg)
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("remove-tournament-from-featured", _, socket) do
    tournament = socket.assigns.tournament

    case Tournaments.update_featured(tournament, %{featured: false}) do
      {:ok, tournament} ->
        socket
        |> assign(tournament: Tournaments.get_tournament!(tournament.id))
        |> then(&{:noreply, &1})

      _ ->
        Logger.error(:error, "Failed to remove #{tournament.title} from the featured list")

        socket
        |> put_flash(:error, "Unable to remove the featured flag from this Tournament")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("open-registrations-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "open-registrations")
    |> assign(:confirmation_message, "Confirm that you want to open registrations now.")
    |> then(&{:noreply, &1})
  end

  def handle_event("open-registrations", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    with {:ok, true} <- can_manage_tournament(current_user, tournament),
         {:ok, _values} <- Tournaments.update_tournament_status(tournament, :registrations_open) do
      socket
      |> track_segment_event("Registrations Opened", %{tournament_id: tournament.id})
      |> push_navigate(
        to: Routes.live_path(socket, StridentWeb.TournamentDashboardLive, tournament.slug)
      )
    else
      {:error, :invalid_permissions} ->
        berate_javascript_hacker_kid(socket)

      _ ->
        put_flash(socket, :error, "Can't open registration for tournament!")
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("close-registrations-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "close-registrations")
    |> assign(:confirmation_message, "Confirm that you want to close registrations now.")
    |> then(&{:noreply, &1})
  end

  def handle_event("close-registrations", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    with(
      {:ok, true} <- can_manage_tournament(current_user, tournament),
      {:ok, _values} <-
        Tournaments.update_tournament_status(tournament, :registrations_closed)
    ) do
      socket
      |> track_segment_event("Registrations Closed", %{tournament_id: tournament.id})
      |> push_navigate(
        to: Routes.live_path(socket, StridentWeb.TournamentDashboardLive, tournament.slug)
      )
    else
      {:error, :invalid_permissions} ->
        berate_javascript_hacker_kid(socket)

      _ ->
        put_flash(socket, :error, "Can't close registration for tournament!")
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("start-tournament-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "start-tournament")
    |> assign(:confirmation_message, "Confirm that you want to start the tournament.")
    |> then(&{:noreply, &1})
  end

  def handle_event("start-tournament", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    with {:ok, true} <- can_manage_tournament(current_user, tournament),
         {:ok, _values} <- tournament_transition_to_in_progress(tournament) do
      socket
      |> track_segment_event("Tournament Started", %{tournament_id: tournament.id})
      |> close_confirmation()
      |> push_navigate(
        to: Routes.live_path(socket, StridentWeb.TournamentDashboardLive, tournament.slug)
      )
    else
      {:error, :invalid_permissions} ->
        socket
        |> berate_javascript_hacker_kid()
        |> close_confirmation()

      {:error, error} ->
        socket
        |> put_string_or_changeset_error_in_flash(error, exclude_field: true)
        |> close_confirmation()
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:show_modal_in_test, %{modal_id: modal_id, show: show}}, socket) do
    if socket.assigns.modal_id == modal_id do
      {:noreply, assign(socket, :show, !!show)}
    else
      {:noreply, socket}
    end
  end

  defp mount_socket_if_can_manage_tournament(socket, slug) do
    cond do
      !socket.assigns.current_user ->
        redirect(socket, to: Routes.live_path(socket, StridentWeb.UserLogInLive))

      !socket.assigns.can_manage_tournament ->
        redirect(socket, to: Routes.tournament_show_pretty_path(socket, :show, slug))

      true ->
        tournament =
          Tournaments.get_tournament_with_preloads_by(
            [slug: slug],
            Setup.tournament_dashboard_preloads()
          )

        participants = Tournaments.list_tournament_participants(tournament.id, limit: 10)

        socket
        |> assign(:page_title, "Dashboard - #{tournament.title}")
        |> assign(
          :user_return_to,
          Routes.live_path(socket, StridentWeb.TournamentDashboardLive, tournament.slug)
        )
        |> assign(:team_site, :dashboard)
        |> assign(:tournament, tournament)
        |> assign(:sorted_players, Tournaments.sort_players_by_stake_and_invitation(participants))
        |> assign(:has_prize_pool, Enum.any?(tournament.prize_pool))
        |> then(&assign(&1, :tournament_link, get_tournament_link(&1)))
        |> then(&assign(&1, :reddit_link, get_link_for_reddit(&1)))
        |> then(&assign(&1, :twitter_link, get_link_for_twitter(&1)))
        |> then(&assign(&1, :mailto_link, get_link_for_mail(&1)))
        |> assign(:filter_options, @filter_options)
        |> assign(:selected_filter, Enum.at(@filter_options, 0))
        |> assign_has_entry_fee()
        |> close_confirmation()
        |> assign_match_chats()
        |> assign_number_of_confirmed_participants()
        |> assign_number_of_participants_still_raising_stakes()
    end
  end

  defp assign_match_chats(socket) do
    %{assigns: %{tournament: tournament}} = socket
    tournament = Strident.Repo.preload(tournament, stages: [matches: :chat])

    tournament.stages
    |> Enum.flat_map(&Enum.map(&1.matches, fn %{chat: chat} -> chat end))
    |> Enum.reject(&is_nil/1)
    |> then(&assign(socket, :chats, &1))
  end

  @spec tournament_transition_to_in_progress(Tournament.t()) ::
          {:ok, Tournament.t()} | {:error, Changeset.t()}
  defp tournament_transition_to_in_progress(%Tournament{status: :registrations_open} = tournament) do
    with {:ok, tournament} <-
           Tournaments.update_tournament_status(tournament, :registrations_closed) do
      tournament_transition_to_in_progress(tournament)
    end
  end

  defp tournament_transition_to_in_progress(
         %Tournament{status: :registrations_closed} = tournament
       ),
       do: Tournaments.update_tournament_status(tournament, :in_progress)

  defp can_manage_tournament(current_user, tournament) do
    case Tournaments.can_manage_tournament?(current_user, tournament) do
      true -> {:ok, true}
      _ -> {:error, :invalid_permissions}
    end
  end

  def assign_has_entry_fee(socket) do
    %{assigns: %{tournament: tournament}} = socket
    assign(socket, :has_entry_fee?, Money.zero?(tournament.buy_in_amount))
  end

  def show_countdown?(tournament, remaining_prize_pool_coverage) do
    tournament.prize_strategy == :prize_pool and
      remaining_overage?(remaining_prize_pool_coverage) and
      compare_current_and_two_days_prior_registrations_close_at(tournament.registrations_close_at) in [
        :lt,
        :eq
      ] and
      tournament.status not in [:cancelled, :finished, :under_review]
  end

  def show_cover_prize_pool?(tournament, remaining_prize_pool_coverage) do
    tournament.prize_strategy == :prize_pool and
      remaining_overage?(remaining_prize_pool_coverage) and
      compare_current_and_two_days_prior_registrations_close_at(tournament.registrations_close_at) ==
        :gt and
      tournament.status != :cancelled
  end

  defp compare_current_and_two_days_prior_registrations_close_at(registrations_close_at) do
    registrations_close_at
    |> Timex.shift(days: -2)
    |> NaiveDateTime.compare(NaiveDateTime.utc_now())
  end

  defp remaining_overage?(remaining_prize_pool_coverage) do
    Money.compare(
      remaining_prize_pool_coverage,
      Money.zero(remaining_prize_pool_coverage.currency)
    ) == :gt
  end

  def get_tournament_link(socket) do
    %{tournament: tournament} = socket.assigns

    tournament
    |> TournamentParticipantsHelpers.fallback_tournament_path()
    |> UrlGeneration.absolute_path()
  end

  def get_link_for_reddit(socket) do
    "http://www.reddit.com/submit?url=" <> get_tournament_link(socket)
  end

  def get_link_for_twitter(socket) do
    "https://twitter.com/share/?text=" <> get_tournament_link(socket)
  end

  def get_link_for_mail(socket) do
    "mailto:?subject=Join us&body=" <> get_tournament_link(socket)
  end

  defp assign_number_of_confirmed_participants(socket) do
    %{assigns: %{tournament: tournament}} = socket
    confirmed_participants = Tournaments.get_number_of_confirmed_participants(tournament)
    assign(socket, :number_of_confirmed_participants, confirmed_participants)
  end

  defp assign_number_of_participants_still_raising_stakes(socket) do
    %{assigns: %{tournament: tournament}} = socket
    %{participants: participants} = Repo.preload(tournament, participants: [])

    participants
    |> Enum.count(&(&1.status != :confirmed))
    |> then(&assign(socket, :number_of_participants_still_raising_stakes, &1))
  end
end
