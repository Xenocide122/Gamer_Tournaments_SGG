defmodule StridentWeb.TournamentPageLive.Show do
  @moduledoc """
  The Tournament show page main Live View

  We should strive to consolidate participants and bracket&seeding into this,
  making them into live components.

  The `:live_action` determines which page we are on.

  Some of the pages should not be accessible for anon, normies and non-staff.
  """
  require Logger
  use StridentWeb, :live_view
  use StridentWeb.TournamentLive.TitleAndSummary.Handler
  alias Ecto.Changeset
  alias Strident.Accounts.User
  alias Strident.Features
  alias Strident.Helpers.DateTimeFormatter
  alias Strident.NotifyClient
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.Stages
  alias Strident.TournamentGeneration
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias StridentWeb.Router.Helpers, as: Routes
  alias StridentWeb.TournamentBracketAndSeedingLive
  alias StridentWeb.TournamentLive.DetailCardsGrid
  alias StridentWeb.TournamentLive.TitleAndSummary
  alias StridentWeb.TournamentParticipantsLive
  alias StridentWeb.UserLogInLive
  alias Phoenix.LiveView.JS

  @live_actions [:show, :bracket_and_seeding, :participants]
  def live_actions, do: @live_actions
  @type live_action :: unquote(Enum.reduce(@live_actions, &{:|, [], [&1, &2]}))

  @impl true
  def mount(params, _session, socket) do
    clauses =
      case params do
        %{"id_or_slug" => id_or_slug} ->
          case Ecto.UUID.cast(id_or_slug) do
            :error -> [slug: id_or_slug]
            {:ok, id} -> [id: id]
          end

        %{"slug" => slug} ->
          [slug: slug]

        %{"vanity_url" => vanity_url} ->
          [vanity_url: vanity_url]
      end

    do_mount(socket, params, clauses)
  end

  @live_actions_allowed_for_anonymous_user [:show]
  @impl true
  def handle_params(params, session, socket) do
    %{current_user: current_user, live_action: live_action, tournament: tournament} =
      socket.assigns

    if live_action in @live_actions_allowed_for_anonymous_user or current_user do
      socket
      |> close_confirmation()
      |> handle_params_for_live_action(params, session)
    else
      user_return_to = Routes.tournament_page_show_path(socket, live_action, tournament.slug)

      socket
      |> push_redirect(
        to: Routes.live_path(socket, UserLogInLive, %{user_return_to: user_return_to})
      )
      |> put_flash(:error, "Please log in to access this page.")
    end
    |> then(&{:noreply, &1})
  end

  defp handle_params_for_live_action(socket, params, session) do
    case socket.assigns.live_action do
      :show ->
        socket

      :bracket_and_seeding ->
        TournamentBracketAndSeedingLive.handle_params(params, session, socket)

      :participants ->
        TournamentParticipantsLive.handle_params(params, session, socket)
    end
  end

  @impl true
  def handle_event("finish-tournament-clicked", _params, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "finish-tournament",
      confirmation_message: "Confirm marking tournament as finished."
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("finish-tournament", _params, socket) do
    socket
    |> update_tournament_status(:finished)
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("cancel-tournament-clicked", _params, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "cancel-tournament",
      confirmation_message: "Confirm cancelling tournament.",
      confirmation_confirm_prompt: "Cancel it",
      confirmation_cancel_prompt: "Don't cancel it"
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("cancel-tournament", _params, socket) do
    socket
    |> update_tournament_status(:cancelled)
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "update-tournament-status",
        %{"tournament" => %{"status" => status}},
        socket
      ) do
    if Tournaments.can_manage_tournament?(
         socket.assigns.current_user,
         socket.assigns.tournament
       ) do
      update_tournament_status(socket, status)
    else
      berate_javascript_hacker_kid(socket)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("open-registrations-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "open-registrations")
    |> assign(:confirmation_message, "Confirm that you want to open registrations now.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("open-registrations", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    with {:ok, true} <- can_manage_tournament(current_user, tournament),
         {:ok, _values} <-
           Tournaments.update_tournament_status(tournament, :registrations_open) do
      socket
      |> track_segment_event("Registrations Opened", %{tournament_id: tournament.id})
      |> push_navigate(
        to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
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

  @impl true
  def handle_event("close-registrations", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    Logger.info(
      "[TOURNAMENT REGISTRATIONS] Closing tournament registrations for tournament #{tournament.id}"
    )

    with(
      {:ok, true} <- can_manage_tournament(current_user, tournament),
      {:ok, tournament} <-
        Tournaments.update_tournament_status(tournament, :registrations_closed)
    ) do
      socket
      |> track_segment_event("Registrations Closed", %{tournament_id: tournament.id})
      |> push_navigate(
        to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
      )
    else
      {:error, :invalid_permissions} ->
        berate_javascript_hacker_kid(socket)

      _error ->
        put_flash(socket, :error, "Can't close registration for tournament!")
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("start-tournament-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "start-tournament")
    |> assign(:confirmation_message, "Confirm that you want to start the tournament.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("start-tournament", _params, socket) do
    %{assigns: %{tournament: tournament, current_user: current_user}} = socket

    with(
      {:ok, true} <- can_manage_tournament(current_user, tournament),
      {:ok, _values} <- tournament_transition_to_in_progress(tournament)
    ) do
      socket
      |> track_segment_event("Tournament Started", %{tournament_id: tournament.id})
      |> push_navigate(
        to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
      )
    else
      {:error, :invalid_permissions} ->
        berate_javascript_hacker_kid(socket)

      false ->
        put_flash(
          socket,
          :error,
          "Can't start tournament as you do not have enough funds to cover prize pool"
        )

      _ ->
        put_flash(socket, :error, "Can't start tournament!")
    end
    |> then(&{:noreply, &1})
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
        "resolve-tied-stage-participant",
        %{
          "stage-participant-id" => sp_id,
          "stage_participant" => %{"new_rank" => new_rank}
        },
        socket
      ) do
    if Tournaments.can_manage_tournament?(
         socket.assigns.current_user,
         socket.assigns.tournament
       ) do
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
  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("restart-tournament-clicked", _params, socket) do
    socket
    |> assign(:show_confirmation, true)
    |> assign(:confirmation_confirm_event, "restart-tournament")
    |> assign(:confirmation_message, "Confirm that you want to generate the matches.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("restart-tournament", _params, socket) do
    %{tournament: tournament, current_user: current_user} = socket.assigns

    if Tournaments.can_manage_tournament?(current_user, tournament) do
      regen(socket)
    else
      berate_javascript_hacker_kid(socket)
    end
  end

  def handle_event("drop-and-refund", %{"participant" => participant_id}, socket) do
    %{can_manage_tournament: can_manage_tournament} = socket.assigns

    if can_manage_tournament do
      %{tournament: tournament} = socket.assigns
      tournament_id = tournament.id

      %{tournament_id: ^tournament_id} =
        participant = Tournaments.get_tournament_participant(participant_id)

      drop_result =
        Tournaments.drop_tournament_participant_from_tournament(participant,
          refund_participant: true
        )

      case drop_result do
        {:ok, _, _} ->
          put_flash(socket, :info, "Participant successfully removed!")

        {:error, error} ->
          put_string_or_changeset_error_in_flash(socket, error)
      end
    else
      put_flash(socket, :error, "You can't perform this action")
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("send-reminder", %{"token" => token}, socket) do
    %{assigns: %{tournament: tournament}} = socket
    invitation = Tournaments.get_invitation_with_preloads_by(invitation_token: token)

    case Tournaments.send_tournament_invitation_email(invitation, tournament) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Reminder email sent successfully!")
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(
          :error,
          "We are unable to send this email. Please contact us through Discord or support@stride.gg"
        )
        |> then(&{:noreply, &1})
    end
  end

  def handle_event(
        "register-n-random-users",
        %{"qa_hacks" => %{"n" => n, "number_party_members" => number_party_members}},
        socket
      ) do
    case socket.assigns do
      %{current_user: %{is_staff: true}} ->
        n = String.to_integer(n)
        number_party_members = String.to_integer(number_party_members)

        {:ok, _register_n_random_users_pid} =
          Strident.QaHacks.register_n_random_users(
            socket.assigns.tournament.slug,
            n,
            number_party_members,
            self()
          )

        socket
        |> put_flash(:info, "You will be redirected when that finishes. Please be patient.")
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> berate_javascript_hacker_kid()
        |> then(&{:noreply, &1})
    end
  end

  defp regen(socket) do
    %{tournament: tournament} = socket.assigns
    allowed_tournament_statuses = [:in_progress, :registrations_open, :registrations_closed]

    if tournament.status in allowed_tournament_statuses do
      opts = [
        allowed_tournament_statuses: [:in_progress, :registrations_open, :registrations_closed]
      ]

      TournamentGeneration.Debouncer.regenerate(tournament.id, opts)

      put_flash(
        socket,
        :info,
        "Matches regeneration has been scheduled. Page will re-load when regeneration finishes."
      )
    else
      put_flash(
        socket,
        :error,
        "Cannot regenerate a #{Tournaments.human_friendly_tournament_description(tournament.status)}"
      )
    end
    |> assign(:show_confirmation, false)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(:photo_upload_started, socket) do
    Logger.debug("Started updating Tournament Banner Image")

    socket
    |> put_flash(:info, "Image started to upload, will be shown when finish.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:photo_upload_finished, tournament}, socket) do
    Logger.debug("Finish updating Tournament Banner Image")

    socket
    |> push_navigate(to: ~p"/t/#{tournament.slug}")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:photo_upload_error, reason}, socket) do
    Logger.error("Error updating Tournament Banner Image: #{inspect(reason)}")
    {:noreply, socket}
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
  def handle_info(:finished_registering_n_random_users, socket) do
    %{tournament: tournament} = socket.assigns

    socket
    |> push_redirect(
      to: Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:tournament_invitation_updated, invitation}, socket) do
    socket
    |> update(:tournament, fn tournament ->
      tournament.participants
      |> Enum.map(fn participant ->
        if participant.id == invitation.tournament_participant_id do
          update_tournament_participant_with_invitation(participant, invitation)
        else
          participant
        end
      end)
      |> then(&%{tournament | participants: &1})
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:updated_tournament_participant, tp}, socket) do
    %{
      live_action: live_action,
      tournament: tournament,
      debug_mode: debug_mode,
      current_user: current_user,
      can_manage_tournament: can_manage_tournament,
      timezone: timezone,
      locale: locale,
      number_of_participants: number_of_participants,
      ranks_frequency: ranks_frequency
    } = socket.assigns

    case live_action do
      :participants ->
        send_update(
          StridentWeb.TournamentParticipantsLive,
          id: "participants-#{tournament.id}",
          tournament: tournament,
          debug_mode: debug_mode,
          current_user: current_user,
          can_manage_tournament: can_manage_tournament,
          timezone: timezone,
          locale: locale,
          number_of_participants: number_of_participants,
          ranks_frequency: ranks_frequency
        )

      _ ->
        :noop
    end

    case Enum.find_index(tournament.participants, &(&1.id == tp.id)) do
      nil ->
        socket

      found_index ->
        fxn = &%{&1 | participants: List.replace_at(&1.participants, found_index, tp)}
        update(socket, :tournament, fxn)
    end
    |> then(&{:noreply, &1})
  end

  def handle_info({:tournament_matches_regenerated, details}, socket) do
    %{tournament_id: tournament_id} = details
    %{tournament: tournament, current_user: current_user} = socket.assigns

    if tournament.id == tournament_id do
      preloads = tournament_preloads_for_current_user(current_user)
      tournament = Tournaments.get_tournament_with_preloads_by([id: tournament_id], preloads)
      {:ok, socket} = mount_tournament(socket, tournament)
      put_flash(socket, :info, "Tournament regenerated, syncing view...")
    else
      socket
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(event, socket) do
    Logger.debug("Got unknown handle_info/2 on Tournament Page #{inspect(event)}.")
    {:noreply, socket}
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

  @spec log_concise_error_and_verbose_info(Socket.t(), term(), String.t()) :: Socket.t()
  defp log_concise_error_and_verbose_info(socket, error, message) do
    metadata = logger_metadata(socket)
    Logger.info(message <> ". #{inspect(error)}", metadata)
    Logger.error(message, metadata)
    socket
  end

  @spec logger_metadata(Socket.t()) :: map()
  defp logger_metadata(socket) do
    %{
      tournament_id: socket.assigns.tournament.id,
      tournament_slug: socket.assigns.tournament.slug,
      stage_id: socket.assigns.stage.id
    }
  end

  defp do_mount(socket, params, clauses) do
    %{current_user: current_user} = socket.assigns
    clauses = Keyword.take(clauses, [:id, :slug, :vanity_url])
    preloads = tournament_preloads_for_current_user(current_user)
    tournament = Tournaments.get_tournament_with_preloads_by(clauses, preloads)

    socket
    |> close_confirmation()
    |> mount_tournament_if_not_deleted(params, tournament)
  end

  @spec tournament_preloads_for_current_user(User.t() | nil) :: [atom() | Keyword.t()]
  defp tournament_preloads_for_current_user(nil = _user) do
    # anon user can only see the show page
    [
      :created_by,
      :game,
      :social_media_links,
      :stages,
      participants: :tournament_invitations
    ]
  end

  defp tournament_preloads_for_current_user(%User{} = _user) do
    # normal user can see participants and brackets and seeding
    [
      :created_by,
      :game,
      :management_personnel,
      :registration_fields,
      :social_media_links,
      participants: :tournament_invitations,
      stages: [
        :settings,
        :child_edges,
        :children,
        :participants,
        matches: [
          :match_reports,
          :child_edges,
          :parent_edges,
          :parents,
          :participants
        ]
      ]
    ]
  end

  def participant_preloads_for_current_user(nil) do
    [:team, :party]
  end

  def participant_preloads_for_current_user(%User{} = _user) do
    [
      :registration_fields,
      :tournament_invitations,
      active_invitation: :user,
      team: [team_members: :user],
      party: [party_members: :user, party_invitations: []],
      players: :user
    ]
  end

  defp mount_tournament_if_not_deleted(socket, params, tournament) do
    case tournament do
      %Tournament{deleted_at: nil} = tournament ->
        socket
        |> assign_debug_mode(params, %{})
        |> mount_tournament(tournament)

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Could not find that tournament")
         |> redirect(to: "/tournaments")}
    end
  end

  defp mount_tournament(socket, tournament) do
    %{entries: participants} =
      TournamentParticipants.paginate_tournament_participants(tournament.id,
        filter_statuses: Tournaments.on_track_statuses(),
        pagination: [page_size: 6]
      )

    socket
    |> assign(:tournament, tournament)
    |> assign(:participants, participants)
    |> assign_tournament_derived_stuff()
    |> tap(fn socket ->
      if connected?(socket), do: maybe_show_new_features(socket)
    end)
    |> assign(:subscribed_participant_ids, [])
    |> subscribe_to_tournament_updates()
    |> subscribe_to_participant_updates()
    |> then(&{:ok, &1})
  end

  defp assign_tournament_derived_stuff(socket) do
    %{live_action: live_action, current_user: current_user, tournament: tournament} =
      socket.assigns

    number_of_participants =
      Enum.count(tournament.participants, &(&1.status in Tournaments.on_track_statuses()))

    ranks_frequency =
      Enum.reduce(tournament.participants, %{}, fn %{rank: rank}, acc ->
        Map.update(acc, rank, 1, &(&1 + 1))
      end)

    socket
    |> assign(:page_title, page_title(live_action, tournament))
    |> assign(:page_description, page_description(tournament))
    |> assign(
      :page_image,
      tournament.cover_image_url || tournament.game.default_game_banner_url
    )
    |> assign(
      :can_manage_tournament,
      Tournaments.can_manage_tournament?(current_user, tournament)
    )
    |> assign(:changeset, Tournaments.change_tournament(tournament, %{}))
    |> assign_display_logic_bools()
    |> assign_tournament_twitch()
    |> assign(:number_of_participants, number_of_participants)
    |> assign(:ranks_frequency, ranks_frequency)
  end

  defp assign_tournament_twitch(socket) do
    %{tournament: tournament} = socket.assigns

    case Tournaments.get_stream_link(tournament) do
      nil -> assign(socket, :twitch_channel_name, nil)
      %{handle: twitch_channel} -> assign(socket, :twitch_channel_name, twitch_channel)
    end
  end

  defp assign_display_logic_bools(socket) do
    # if we are using handle_info to update tournament in realtime, we will want to re-assign this stuff
    %{tournament: tournament, current_user: current_user} = socket.assigns

    is_user_participating_in_tournament =
      Tournaments.is_user_participating_in_tournament?(tournament, current_user)

    is_watch_stream_button_shown =
      tournament.status in [:in_progress, :under_review, :finished] and
        Enum.reduce_while(tournament.social_media_links, false, fn link, _ ->
          case SocialMediaLink.add_type(link) do
            %{type: :stream} -> {:halt, true}
            _ -> {:cont, false}
          end
        end)

    show_contribution_button =
      tournament.prize_strategy == :prize_distribution and
        (tournament.status in [:registrations_open, :registrations_closed, :scheduled] or
           (tournament.status == :in_progress and not Tournaments.is_almost_finished?(tournament)))

    show_fund_participant_button =
      tournament.allow_staking and tournament.status in [:scheduled, :registrations_open]

    are_more_participants_allowed =
      is_nil(tournament.required_participant_count) ||
        tournament.required_participant_count >
          Tournaments.get_number_of_confirmed_participants(tournament)

    show_registration_link =
      tournament.type == :casting_call and tournament.status == :registrations_open and
        are_more_participants_allowed and not is_user_participating_in_tournament

    display_logic_bools = %{
      is_user_participating_in_tournament: is_user_participating_in_tournament,
      is_watch_stream_button_shown: is_watch_stream_button_shown,
      show_contribution_button: show_contribution_button,
      show_fund_participant_button: show_fund_participant_button,
      show_registration_link: show_registration_link
    }

    assign(socket, display_logic_bools)
  end

  defp maybe_show_new_features(%{assigns: %{current_user: nil}}), do: nil

  defp maybe_show_new_features(socket) do
    %{
      current_user: current_user,
      tournament: tournament,
      can_manage_tournament: can_manage_tournament,
      is_user_participating_in_tournament: is_user_participating_in_tournament
    } = socket.assigns

    features =
      [user: current_user, tags: [:tournament]]
      |> Features.list_features()
      |> Enum.reject(fn
        feature ->
          (not is_user_participating_in_tournament and
             :tournament_participant in feature.tags) or
            (not can_manage_tournament and :can_manage_tournament in feature.tags)
      end)

    if Enum.any?(features) do
      send_update(StridentWeb.Live.Components.NewFeaturePopups,
        id: "feature-popups",
        activate_popup: true,
        features: features,
        title: "New Tournament Features",
        description:
          "Check out the features that you'll have access to once the tournament starts on #{tournament.starts_at}!"
      )
    end
  end

  defp page_title(:show, tournament), do: tournament.title
  defp page_title(:bracket_and_seeding, tournament), do: "Bracket&Seeding - #{tournament.title}"
  defp page_title(:participants, tournament), do: "Participants - #{tournament.title}"

  defp page_description(tournament) do
    formatted_starts_at =
      DateTimeFormatter.format_datetime(tournament.starts_at, "America/New_York", "en")

    "#{tournament.game.title} tournament on Stride @ #{formatted_starts_at}"
  end

  defp update_tournament_status(socket, status) do
    %{tournament: tournament, current_user: current_user} = socket.assigns

    case Tournaments.update_tournament_status(tournament, status,
           preloads: tournament_preloads_for_current_user(current_user)
         ) do
      {:ok, %{status: new_status} = tournament} ->
        socket
        |> assign(:tournament, tournament)
        |> put_flash(:info, "Changed tournament status to #{new_status}")

      {:error, error} ->
        socket
        |> log_concise_error_and_verbose_info(error, "Error updating tournament status")
        |> put_string_or_changeset_error_in_flash(error)
    end
  end

  defp update_tournament_participant_with_invitation(participant, invitation) do
    tournament_invitations =
      if invitation.id in Enum.map(participant.tournament_invitations, & &1.id) do
        Enum.map(participant.tournament_invitations, fn tournament_invitation ->
          if tournament_invitation.id == invitation.id do
            invitation
          else
            tournament_invitation
          end
        end)
      else
        [invitation | participant.tournament_invitations]
      end

    case invitation do
      %{status: status} when status in [:pending, :accepted] ->
        %{
          participant
          | active_invitation: invitation,
            tournament_invitations: tournament_invitations
        }

      _ ->
        %{
          participant
          | active_invitation: nil,
            tournament_invitations: tournament_invitations
        }
    end
  end

  defp subscribe_to_participant_updates(socket) do
    if connected?(socket) do
      %{participants: participants} = socket.assigns

      tap(socket, fn _ ->
        Enum.each(participants, &NotifyClient.subscribe_to_events_affecting/1)
      end)
    else
      socket
    end
  end

  defp subscribe_to_tournament_updates(socket) do
    tap(socket, fn _ ->
      if connected?(socket) do
        %{tournament: tournament} = socket.assigns
        NotifyClient.subscribe_to_events_affecting(tournament)
      end
    end)
  end
end
