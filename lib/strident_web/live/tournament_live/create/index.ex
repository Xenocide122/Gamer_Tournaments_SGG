defmodule StridentWeb.TournamentLive.Create.Index do
  @moduledoc false

  use StridentWeb, :live_view

  require Logger

  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.DraftForms
  alias Strident.DraftForms.CreateTournament
  alias Strident.DraftForms.CreateTournament.TournamentInfo
  alias Strident.Games
  alias Strident.PrizeLogic
  alias Strident.Prizes
  alias Strident.Stages
  alias Strident.Tournaments.Tournament
  alias StridentWeb.SegmentAnalyticsHelpers
  alias StridentWeb.TournamentLive.Create.BracketsStructure, as: BracketsStructurePage
  alias StridentWeb.TournamentLive.Create.Confirmation
  alias StridentWeb.TournamentLive.Create.CustomTournament
  alias StridentWeb.TournamentLive.Create.Invites
  alias StridentWeb.TournamentLive.Create.Landing
  alias StridentWeb.TournamentLive.Create.PageNavButtons
  alias StridentWeb.TournamentLive.Create.PageProgress
  alias StridentWeb.TournamentLive.Create.Payment
  alias StridentWeb.TournamentLive.Create.TournamentInfo, as: TournamentInfoPage
  alias StridentWeb.TournamentLive.Create.TournamentType, as: TournamentTypePage
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  @autosave_debounce_ms 1 * 1_000

  @pages Ecto.Enum.values(CreateTournament, :current_page)
  @type page_type :: unquote(Enum.reduce(@pages, &{:|, [], [&1, &2]}))

  @stages_structures Ecto.Enum.values(CreateTournament, :stages_structure)
  @type stages_structure :: unquote(Enum.reduce(@stages_structures, &{:|, [], [&1, &2]}))

  @initial_money Money.new(:USD, 0)

  @spec put_validate_action_if_mounting_to_later_page(Changeset.t()) :: Changeset.t()
  defp put_validate_action_if_mounting_to_later_page(changeset) do
    current_page = Changeset.get_field(changeset, :current_page)

    if current_page in [:tournament_info, :invites, :confirmation] do
      Map.put(changeset, :action, :validate)
    else
      changeset
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    %{
      assigns: %{
        current_user: %User{} = current_user,
        ip_location: ip_location
      }
    } = socket

    games = Games.list_games()
    platforms = Ecto.Enum.mappings(TournamentInfo, :platform)
    prize_strategies = Ecto.Enum.mappings(TournamentInfo, :prize_strategy)
    locations = Ecto.Enum.mappings(TournamentInfo, :location)

    %Ecto.Changeset{} =
      changeset =
      current_user
      |> DraftForms.get_specific_changeset(:create_tournament)
      |> put_validate_action_if_mounting_to_later_page()

    saved_forms = DraftForms.list_saved_form_summaries(current_user, :create_tournament)

    socket
    |> close_confirmation()
    |> assign(:games, games)
    |> assign(:platforms, platforms)
    |> assign(:prize_strategies, prize_strategies)
    |> assign(:locations, locations)
    |> assign(:page_title, "Create your tournament on Stride")
    |> assign(:saved_forms, saved_forms)
    |> assign(:ip_location, ip_location)
    |> initialize_form(changeset)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(params, _session, socket) do
    page = get_page_from_params(params)

    socket
    |> push_event("close-spinner", %{})
    |> assign(:current_page, page)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("back-to-landing", _params, socket) do
    socket
    |> update_current_page(:landing)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "clicked-tournament-type",
        %{"type" => tournament_type},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    stages_structure = Changeset.get_field(changeset, :stages_structure)
    next_page = if(stages_structure == :two_stage, do: :stages, else: :tournament_info)

    socket
    |> update_changeset(%{tournament_type: tournament_type, current_page: next_page})
    |> assign_pages_and_current_page()
    |> schedule_save()
    |> then(fn %{assigns: %{current_page: page}} = socket ->
      push_patch(socket, to: Routes.create_tournament_path(socket, :index, page))
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("clicked-saved-form", %{"id" => id}, socket) do
    case DraftForms.get_saved_draft_form_as_changeset(id) do
      nil ->
        socket
        |> put_flash(:error, "Unable to copy saved form data")
        |> then(&{:noreply, &1})

      changeset ->
        socket
        |> initialize_form(changeset)
        |> update_current_page(:tournament_type)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("clicked-stages-structure", %{"type" => "custom-tournament"}, socket) do
    socket
    |> update_current_page(:custom_tournament)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("clicked-stages-structure", %{"type" => new_stages_structure}, socket) do
    new_stages_structure = String.to_existing_atom(new_stages_structure)

    case {Changeset.get_field(socket.assigns.changeset, :stages), new_stages_structure} do
      {%{types: [stages_structure]}, stages_structure} -> %{}
      {%{types: [_two, _types]}, :two_stage} -> %{}
      {%{types: _}, :two_stage} -> %{stages: %{types: [:round_robin, :single_elimination]}}
      {%{types: _}, new_stages_structure} -> %{stages: %{types: [new_stages_structure]}}
    end
    |> Map.merge(%{current_page: :tournament_type, stages_structure: new_stages_structure})
    |> then(&update_changeset(socket, &1))
    |> assign_pages_and_current_page()
    |> schedule_save()
    |> then(fn %{assigns: %{current_page: page}} = socket ->
      push_patch(socket, to: Routes.create_tournament_path(socket, :index, page))
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-another-prize", _, socket) do
    socket
    |> update_tournament_info_changeset(&add_another_prize/3)
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-prize", _, socket) do
    socket
    |> update_tournament_info_changeset(&remove_prize/3)
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("use-recommended-prize-pool", _, socket) do
    socket
    |> update_tournament_info_changeset(&use_recommended_prize_pool/3)
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-new-registration-field", _params, socket) do
    socket
    |> update_tournament_info_changeset(&add_registration_field/3)
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-another-stat-label", _, socket) do
    socket
    |> update_tournament_info_changeset(&add_another_stat_label/3)
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-registration-field", %{"index" => index_raw}, socket) do
    {index, _} = Integer.parse(index_raw)

    socket
    |> update_tournament_info_changeset(&remove_registration_field(&1, index, &2, &3))
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-stat-label", _, socket) do
    socket
    |> update_tournament_info_changeset(&remove_stat_label/3)
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("do-nothing", _unsigned_params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"create_tournament" => unsigned_params}, socket) do
    socket
    |> update_changeset(unsigned_params)
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change", _unsigned_params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("back", _unsigned_params, socket) do
    socket.assigns.pages
    |> previous_page(socket.assigns.current_page)
    |> then(&update_current_page(socket, &1))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("next", _unsigned_params, socket) do
    socket.assigns.pages
    |> next_page(socket.assigns.current_page)
    |> then(&update_current_page(socket, &1))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reset-form-clicked", _unsigned_params, socket) do
    socket
    |> assign(%{
      show_confirmation: true,
      confirmation_confirm_event: "reset-form",
      confirmation_message: "Do you really want to reset the form and start over?",
      confirmation_confirm_prompt: "Yes",
      confirmation_cancel_prompt: "No"
    })
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reset-form", _unsigned_params, socket) do
    socket
    |> reset_form()
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change-page", %{"page" => page}, socket) do
    socket
    |> update_current_page(page)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-in-bulk", _unsigned_params, socket) do
    Logger.warning("Unimplemented Add In Bulk")
    {:noreply, socket}
  end

  def handle_event("create_tournament", _unsigned_params, socket) do
    socket
    |> create_tournament()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("show-spinner", _, socket) do
    socket
    |> push_event("show-spinner", %{})
    |> then(&{:noreply, &1})
  end

  def handle_event("close-confirmation", _params, socket) do
    socket
    |> close_confirmation()
    |> then(&{:noreply, &1})
  end

  def handle_event(
        "set_lat_lng",
        %{"lat" => lat, "lng" => lng, "full_address" => full_address} = _attrs,
        socket
      ) do
    socket
    |> update_tournament_info_changeset(
      &TournamentInfo.changeset(&1, %{lat: lat, lng: lng, full_address: full_address}, &2, &3)
    )
    |> schedule_save()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(:store, socket) do
    {:noreply, store_draft_form(socket)}
  end

  @spec update_current_page(Socket.t(), page_type()) :: Socket.t()
  defp update_current_page(socket, new_current_page) do
    socket
    |> update_changeset(%{current_page: new_current_page})
    |> assign_pages_and_current_page()
    |> schedule_save()
    |> then(fn %{assigns: %{current_page: page}} = socket ->
      push_patch(socket, to: Routes.create_tournament_path(socket, :index, page: page))
    end)
  end

  @impl true
  def terminate(_reason, %{assigns: %{skip_store_on_terminate: true}}) do
    :ok
  end

  @impl true
  def terminate(_reason, socket) do
    store_draft_form(socket)
    :ok
  end

  @spec update_changeset(Socket.t(), map()) :: Socket.t()
  defp update_changeset(%{assigns: %{changeset: changeset}} = socket, params) do
    changeset
    |> CreateTournament.changeset(params)
    |> Map.put(:action, :validate)
    |> then(&assign(socket, :changeset, &1))
  end

  @spec assign_pages_and_current_page(Socket.t()) :: Socket.t()
  defp assign_pages_and_current_page(socket) do
    %{
      assigns: %{
        changeset: changeset
      }
    } = socket

    current_page = Changeset.get_field(changeset, :current_page)
    stages_structure = Changeset.get_field(changeset, :stages_structure)
    tournament_type = Changeset.get_field(changeset, :tournament_type)

    pages =
      @pages
      |> Enum.reject(fn
        page -> reject_page(page, stages_structure, tournament_type)
      end)

    socket
    |> assign(:current_page, current_page)
    |> assign(:stages_structure, stages_structure)
    |> assign(:pages, pages)
    |> assign_invited_users()
  end

  @spec reject_page(page_type(), stages_structure(), Tournament.type()) :: boolean()
  defp reject_page(:invites, _, :casting_call), do: true
  defp reject_page(:stages, :two_stage, _), do: false
  defp reject_page(:stages, _, _), do: true
  defp reject_page(_, _, _), do: false

  @spec next_page([page_type()], page_type()) :: page_type()
  defp next_page(pages, current_page) do
    next_or_previous_page(pages, current_page, 1)
  end

  @spec previous_page([page_type()], page_type()) :: page_type()
  defp previous_page(pages, current_page) do
    next_or_previous_page(pages, current_page, -1)
  end

  @spec next_or_previous_page([page_type()], page_type(), 1 | -1) :: page_type()
  defp next_or_previous_page(pages, current_page, index_diff) do
    case Enum.find_index(pages, &(&1 == current_page)) do
      nil ->
        Logger.warning("Unable to find page #{current_page} in #{inspect(pages)}")
        List.first(pages)

      page_index ->
        page_index
        |> Kernel.+(index_diff)
        |> max(0)
        |> min(Enum.count(pages) - 1)
        |> then(&Enum.at(pages, &1))
    end
  end

  @spec schedule_save(Socket.t()) :: Socket.t()
  defp schedule_save(socket) do
    unless is_nil(socket.assigns.schedule_ref),
      do: Process.cancel_timer(socket.assigns.schedule_ref)

    schedule_ref = Process.send_after(self(), :store, @autosave_debounce_ms)
    assign(socket, :schedule_ref, schedule_ref)
  end

  @spec store_draft_form(Socket.t()) :: Socket.t()
  defp store_draft_form(%{assigns: %{current_user: current_user, changeset: changeset}} = socket) do
    case DraftForms.store_draft_form(current_user, changeset) do
      {:ok, _draft_form} ->
        socket

      {:error, changeset} ->
        Logger.warning(
          "Error saving tournament creation draft form for user #{current_user.id}: #{inspect(changeset, pretty: true)}"
        )

        socket
    end
  end

  @spec assign_invited_users(Socket.t()) :: Socket.t()
  defp assign_invited_users(socket) do
    need_to_reload_users =
      socket.assigns.current_page == :confirmation or
        (Enum.empty?(socket.assigns.invited_users) and socket.assigns.current_page == :payment)

    if need_to_reload_users do
      invites = Changeset.get_field(socket.assigns.changeset, :invites)

      invited_users =
        Accounts.list_users_for_emails(invites.emails)
        |> Accounts.filter_users_by_credential_type()

      assign(socket, :invited_users, invited_users)
    else
      socket
    end
  end

  @spec create_tournament(Socket.t()) :: Socket.t()
  defp create_tournament(%{assigns: %{changeset: %{valid?: false}}} = socket) do
    socket
    |> go_to_invalid_page()
    |> put_flash(:error, "Please correct any errors to continue.")
  end

  defp create_tournament(
         %{assigns: %{changeset: changeset, current_user: %User{} = current_user}} = socket
       ) do
    case CreateTournament.do_create(changeset, current_user) do
      {:ok, tournament} ->
        socket
        |> SegmentAnalyticsHelpers.track_segment_event("Tournament Created", %{
          tournament_id: tournament.id,
          game_title: tournament.game.title,
          type: tournament.type,
          stage_structure: Changeset.get_field(changeset, :stages_structure),
          prize_pool_strategy: tournament.prize_strategy,
          number_of_participants: tournament.required_participant_count,
          platform: tournament.platform,
          start_date: tournament.starts_at,
          participant_limit: tournament.required_participant_count,
          privacy_setting: if(tournament.is_public, do: "Show", else: "Hidden"),
          challenges_setting: "Disabled",
          entry_fee: tournament.buy_in_amount,
          registrations_open_at: tournament.registrations_open_at,
          registrations_close_at: tournament.registrations_close_at,
          tournament_organizer_username: current_user.display_name
        })
        |> delete_this_draft_form()
        |> put_flash(:info, "Tournament created!")
        |> push_navigate(
          to:
            Routes.live_path(
              StridentWeb.Endpoint,
              StridentWeb.TournamentDashboardLive,
              tournament.slug
            )
        )

      {:error, error} when is_binary(error) ->
        socket
        |> put_flash(:error, error)
        |> go_to_invalid_page()

      {:error, %Changeset{} = changeset} ->
        socket
        |> put_humanized_changeset_errors_in_flash(changeset)
        |> go_to_invalid_page()
    end
  end

  defp go_to_invalid_page(%{assigns: %{changeset: %{valid?: false} = changeset}} = socket) do
    invalid_pages =
      changeset.changes
      |> Enum.reduce([], fn
        {page_name, %Changeset{valid?: false}}, invalid_pages -> [page_name | invalid_pages]
        _, invalid_pages -> invalid_pages
      end)

    new_current_page = List.first(invalid_pages)

    update_current_page(socket, new_current_page)
  end

  defp go_to_invalid_page(socket), do: socket

  @spec update_tournament_info_changeset(
          Socket.t(),
          (Changeset.t(), [Stages.stage_type()], Tournament.type() -> Changeset.t())
        ) :: Socket.t()
  defp update_tournament_info_changeset(%{assigns: %{changeset: changeset}} = socket, update_fun) do
    stage_types =
      changeset
      |> Changeset.get_field(:stages)
      |> Map.get(:types, [])

    tournament_type = Changeset.get_field(changeset, :tournament_type)

    changeset
    |> Changeset.get_change(:tournament_info)
    |> then(&update_fun.(&1, stage_types, tournament_type))
    |> then(fn tournament_info_changeset ->
      update_changeset(socket, %{"tournament_info" => tournament_info_changeset.params})
    end)
  end

  @spec add_registration_field(Changeset.t(), [Stages.stage_type()], Tournament.type()) ::
          Changeset.t()
  defp add_registration_field(tournament_info_changeset, stage_types, tournament_type) do
    case Changeset.get_change(tournament_info_changeset, :registration_fields) do
      nil ->
        TournamentInfo.changeset(
          tournament_info_changeset,
          %{registration_fields: [%{}]},
          stage_types,
          tournament_type
        )

      registration_fields ->
        registration_fields =
          Enum.slide([%{} | Enum.map(registration_fields, &Map.get(&1, :params))], 0, -1)

        TournamentInfo.changeset(
          tournament_info_changeset,
          %{registration_fields: registration_fields},
          stage_types,
          tournament_type
        )
    end
  end

  @spec remove_registration_field(
          Changeset.t(),
          non_neg_integer(),
          [Stages.stage_type()],
          Tournament.type()
        ) :: Changeset.t()
  def remove_registration_field(tournament_info_changeset, index, stage_types, tournament_type) do
    case Changeset.get_field(tournament_info_changeset, :registration_fields) do
      nil ->
        tournament_info_changeset

      registration_fields ->
        registration_fields =
          registration_fields
          |> List.delete_at(index)
          |> Enum.map(&Map.from_struct/1)

        TournamentInfo.changeset(
          tournament_info_changeset,
          %{registration_fields: registration_fields},
          stage_types,
          tournament_type
        )
    end
  end

  @spec add_another_prize(Changeset.t(), [Stages.stage_type()], Tournament.type()) ::
          Changeset.t()
  defp add_another_prize(tournament_info_changeset, stage_types, tournament_type) do
    case Changeset.get_field(tournament_info_changeset, :prize_strategy) do
      :prize_pool ->
        prize_pool = Changeset.get_field(tournament_info_changeset, :prize_pool)
        lowest_rank = Prizes.lowest_prize_pool_rank(prize_pool) || -1
        next_rank = to_string(lowest_rank + 1)
        new_prize_pool = Map.put(prize_pool, next_rank, @initial_money)

        TournamentInfo.changeset(
          tournament_info_changeset,
          %{prize_pool: new_prize_pool},
          stage_types,
          tournament_type
        )

      :prize_distribution ->
        prize_distribution = Changeset.get_field(tournament_info_changeset, :prize_distribution)
        lowest_rank = Prizes.lowest_prize_pool_rank(prize_distribution) || -1
        next_rank = to_string(lowest_rank + 1)
        initial_prize_percentage = if next_rank == "0", do: Decimal.new(100), else: Decimal.new(0)
        new_prize_distribution = Map.put(prize_distribution, next_rank, initial_prize_percentage)

        TournamentInfo.changeset(
          tournament_info_changeset,
          %{prize_distribution: new_prize_distribution},
          stage_types,
          tournament_type
        )
    end
  end

  @spec remove_prize(Changeset.t(), [Stages.stage_type()], Tournament.type()) :: Changeset.t()
  defp remove_prize(tournament_info_changeset, stage_types, tournament_type) do
    case Changeset.get_field(tournament_info_changeset, :prize_strategy) do
      :prize_pool ->
        prize_pool = Changeset.get_field(tournament_info_changeset, :prize_pool)
        lowest_rank = Prizes.lowest_prize_pool_rank(prize_pool)
        new_prize_pool = Map.drop(prize_pool, [lowest_rank])

        TournamentInfo.changeset(
          tournament_info_changeset,
          %{prize_pool: new_prize_pool},
          stage_types,
          tournament_type
        )

      :prize_distribution ->
        prize_distribution = Changeset.get_field(tournament_info_changeset, :prize_distribution)
        lowest_rank = Prizes.lowest_prize_pool_rank(prize_distribution)
        new_prize_distribution = Map.drop(prize_distribution, [lowest_rank])

        TournamentInfo.changeset(
          tournament_info_changeset,
          %{prize_distribution: new_prize_distribution},
          stage_types,
          tournament_type
        )
    end
  end

  @spec add_another_stat_label(Changeset.t(), [Stages.stage_type()], Tournament.type()) ::
          Changeset.t()
  defp add_another_stat_label(tournament_info_changeset, stage_types, tournament_type) do
    stat_labels = Changeset.get_field(tournament_info_changeset, :stat_labels) || [""]
    new_stat_labels = List.insert_at(stat_labels, -1, "")

    TournamentInfo.changeset(
      tournament_info_changeset,
      %{stat_labels: new_stat_labels},
      stage_types,
      tournament_type
    )
  end

  @spec remove_stat_label(Changeset.t(), [Stages.stage_type()], Tournament.type()) ::
          Changeset.t()
  defp remove_stat_label(tournament_info_changeset, stage_types, tournament_type) do
    stat_labels = Changeset.get_field(tournament_info_changeset, :stat_labels) || []
    new_stat_labels = List.delete_at(stat_labels, -1)

    TournamentInfo.changeset(
      tournament_info_changeset,
      %{stat_labels: new_stat_labels},
      stage_types,
      tournament_type
    )
  end

  @recommended_min_split Decimal.new("0.5")

  @spec use_recommended_prize_pool(Changeset.t(), [Stages.stage_type()], Tournament.type()) ::
          Changeset.t()
  defp use_recommended_prize_pool(tournament_info_changeset, stage_types, tournament_type) do
    with number_of_participants when is_integer(number_of_participants) <-
           Changeset.get_field(tournament_info_changeset, :number_of_participants),
         %Money{} = buy_in_amount <-
           Changeset.get_field(tournament_info_changeset, :buy_in_amount),
         %Decimal{} = prize_reducer <-
           Changeset.get_field(tournament_info_changeset, :prize_reducer),
         organizer_wants <-
           Changeset.get_field(tournament_info_changeset, :organizer_wants),
         recommended_prize_pool <-
           PrizeLogic.recommended_prize_pool(
             number_of_participants,
             buy_in_amount,
             @recommended_min_split,
             prize_reducer,
             organizer_wants
           ) do
      TournamentInfo.changeset(
        tournament_info_changeset,
        %{
          prize_pool: recommended_prize_pool,
          prize_distribution:
            Prizes.infer_prize_distribution_from_prize_pool(recommended_prize_pool)
        },
        stage_types,
        tournament_type
      )
    else
      _ -> tournament_info_changeset
    end
  end

  @spec delete_this_draft_form(Socket.t()) :: Socket.t()
  defp delete_this_draft_form(socket) do
    socket
    |> assign(:skip_store_on_terminate, true)
    |> tap(fn _ ->
      DraftForms.save_draft_form(socket.assigns.current_user, :create_tournament)
    end)
  end

  @spec reset_form(Socket.t()) :: Socket.t()
  defp reset_form(socket) do
    case DraftForms.reset_draft_form(socket.assigns.current_user, :create_tournament,
           return_changeset: true
         ) do
      {:ok, new_changeset} ->
        socket
        |> initialize_form(new_changeset)
        |> then(fn socket ->
          push_patch(socket, to: Routes.create_tournament_path(socket, :index, :landing))
        end)

      {:error, %Ecto.Changeset{} = changeset} ->
        put_humanized_changeset_errors_in_flash(socket, changeset)

      {:error, error} when is_binary(error) ->
        put_flash(socket, :error, error)
    end
  end

  @spec initialize_form(Socket.t(), Ecto.Changeset.t()) :: Socket.t()
  defp initialize_form(socket, changeset) do
    socket
    |> assign(:changeset, changeset)
    |> assign(:invited_users, [])
    |> assign_pages_and_current_page()
    |> assign(:schedule_ref, nil)
  end

  @spec get_page_from_params(map()) :: page_type()
  defp get_page_from_params(%{"page" => "stages"}), do: :stages
  defp get_page_from_params(%{"page" => "tournament_type"}), do: :tournament_type
  defp get_page_from_params(%{"page" => "tournament_info"}), do: :tournament_info
  defp get_page_from_params(%{"page" => "invites"}), do: :invites
  defp get_page_from_params(%{"page" => "confirmation"}), do: :confirmation
  defp get_page_from_params(%{"page" => "payment"}), do: :payment
  defp get_page_from_params(%{"page" => "custom_tournament"}), do: :custom_tournament
  defp get_page_from_params(_), do: :landing
end
