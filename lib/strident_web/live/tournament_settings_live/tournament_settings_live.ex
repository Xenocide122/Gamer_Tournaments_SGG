defmodule StridentWeb.TournamentSettingsLive do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias Ecto.Changeset
  alias Strident.ChangesetUtils
  alias Strident.DraftForms.CreateTournament.BracketsStructure, as: BracketsStructureForm
  alias Strident.MatchesGeneration
  alias Strident.Search
  alias Strident.SocialMedia
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.Stages.StageSetting
  alias Strident.Tiebreaking.TiebreakerStrategy
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias Strident.Tournaments.TournamentManagementPersonnel
  alias StridentWeb.SegmentAnalyticsHelpers
  alias StridentWeb.TournamentManagment.Setup
  alias Phoenix.LiveView.Socket

  on_mount({StridentWeb.InitAssigns, :default})

  @preloads [
    participants: [],
    game: [],
    social_media_links: [],
    management_personnel: :user,
    stages: [
      :settings,
      :child_edges,
      :children,
      :participants,
      :tiebreaker_strategy,
      matches: [
        :match_reports,
        :child_edges,
        :parent_edges,
        :parents,
        [participants: :tournament_participant]
      ]
    ]
  ]

  @impl true
  def mount(params, _session, socket) do
    %{"slug" => slug} = params

    with {:cont, %{assigns: %{can_manage_tournament: true}} = socket} <-
           Setup.do_can_manage_tournament(socket, slug),
         {:cont, socket} <- Setup.do_on_mount(socket, slug, @preloads) do
      %{tournament: tournament} = socket.assigns

      socket
      |> reset_form()
      |> assign_page_and_team_site(params)
      |> assign(:page_title, "Settings - #{tournament.title}")
    else
      _ ->
        redirect(socket, to: Routes.tournament_show_pretty_path(socket, :show, slug))
    end
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(params, _session, socket) do
    socket
    |> assign_page_and_team_site(params)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:tournament_updated, params}, %{assigns: %{tournament: tournament}} = socket) do
    case Tournaments.update_tournament(tournament, params) do
      {:ok, tournament} ->
        socket
        |> assign(:tournament, tournament)
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("reset-form", _, socket) do
    socket
    |> reset_form()
    |> then(&{:noreply, &1})
  end

  def handle_event("save-changes", _, socket) do
    socket
    |> save_changed_valid_changesets()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("update-tournament", %{"tournament" => params}, socket) do
    socket
    |> assign_tournament_changeset(params)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("set_lat_lng", attrs, socket) do
    socket
    |> assign_tournament_changeset(attrs)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("update-discord-invitation", %{"social_media_link" => params}, socket) do
    %{"user_input" => user_input} = params

    socket
    |> assign_discord_sml_changeset(user_input)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("update-stream-link", %{"social_media_link" => params}, socket) do
    %{"index" => index_string, "user_input" => user_input} = params
    index = String.to_integer(index_string)

    socket
    |> update_stream_sml_changesets(index, user_input)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-stream-link", _params, socket) do
    socket
    |> add_stream_sml_changeset()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-stream-link", %{"index" => index_string}, socket) do
    index = String.to_integer(index_string)

    socket
    |> remove_stream_sml_changeset(index)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-mgmt", params, socket) do
    %{"user-id" => user_id} = params

    socket
    |> add_mgmt_changeset(user_id)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-mgmt", %{"index" => index_string}, socket) do
    index = String.to_integer(index_string)

    socket
    |> remove_mgmt_changeset(index)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("search-users-for-mgmt", %{"new_mgmt" => params}, socket) do
    %{"user_input" => user_input} = params

    socket
    |> search_users_for_mgmt(user_input)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change-stage-setting", %{"stage_setting" => params}, socket) do
    params =
      case Map.get(params, "setting") do
        "enable_custom_input" ->
          params |> Map.get("custom_input") |> then(&Map.put(params, "setting", &1))

        _ ->
          params
      end

    %{"stage_id" => stage_id, "index" => index_string, "setting" => value} = params

    index = String.to_integer(index_string)

    socket
    |> update_stage_setting_changesets(stage_id, index, value)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change-ties", %{"tiebreaker_strategy" => params}, socket) do
    %{"stage_id" => stage_id} = params

    steps =
      Stream.unfold(0, fn i ->
        case Map.get(params, "#{i}") do
          nil -> nil
          val -> {String.to_existing_atom(val), i + 1}
        end
      end)
      |> Enum.uniq()

    socket
    |> update_tiebreaker_strategy_changesets(stage_id, steps)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("clicked-stages-structure", %{"type" => new_stages_structure}, socket) do
    %{tournament: tournament} = socket.assigns
    current_types = tournament.stages |> Enum.sort_by(& &1.round) |> Enum.map(& &1.type)
    new_stages_structure = String.to_existing_atom(new_stages_structure)

    new_types =
      if new_stages_structure == :two_stage do
        if Enum.count(current_types) == 2 do
          current_types
        else
          [:round_robin, :single_elimination]
        end
      else
        [new_stages_structure]
      end

    num_types = Enum.count(new_types)

    stages_structure =
      case num_types do
        1 -> List.first(new_types)
        2 -> :two_stage
        _ -> raise "unsupported number of stage types #{num_types}"
      end

    new_brackets_structure_changeset =
      BracketsStructureForm.changeset(%BracketsStructureForm{types: current_types}, %{
        types: new_types
      })

    assigns = %{
      brackets_structure_changeset: new_brackets_structure_changeset,
      stages_structure: stages_structure
    }

    socket
    |> assign(assigns)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change-brackets-structure", params, socket) do
    %{"brackets_structure" => %{"stages" => %{"types" => types}}} = params

    new_brackets_structure_changeset =
      BracketsStructureForm.changeset(%BracketsStructureForm{}, %{types: types})

    assigns = %{brackets_structure_changeset: new_brackets_structure_changeset}

    socket
    |> assign(assigns)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("regen-with-new-brackets-structure", _params, socket) do
    %{
      brackets_structure_changeset: brackets_structure_changeset,
      tournament: tournament,
      can_manage_tournament: can_manage_tournament
    } = socket.assigns

    if can_manage_tournament do
      new_stage_types = Changeset.get_field(brackets_structure_changeset, :types)

      case MatchesGeneration.regenerate_tournament(tournament, new_stage_types: new_stage_types) do
        {:ok, _, _} ->
          path = Routes.tournament_page_show_path(socket, :bracket_and_seeding, tournament.slug)

          socket
          |> put_flash(:info, "Regenerating now...")
          |> push_navigate(to: path)

        {:error, error} ->
          put_string_or_changeset_error_in_flash(socket, error)
      end
    else
      socket
    end
    |> then(&{:noreply, &1})
  end

  defp assign_brackets_structure_changeset(socket) do
    %{tournament: tournament} = socket.assigns
    stage_types = tournament.stages |> Enum.sort_by(& &1.round) |> Enum.map(& &1.type)

    brackets_structure_changeset =
      BracketsStructureForm.changeset(%BracketsStructureForm{types: stage_types}, %{
        types: stage_types
      })

    num_types = Enum.count(stage_types)

    stages_structure =
      case num_types do
        0 -> :single_elimination
        1 -> List.first(stage_types)
        2 -> :two_stage
        _ -> raise "unsupported number of stage types #{num_types}"
      end

    assigns = %{
      brackets_structure_changeset: brackets_structure_changeset,
      stages_structure: stages_structure
    }

    assign(socket, assigns)
  end

  def assign_page_and_team_site(socket, params) do
    page =
      case Map.get(params, "page") do
        "match-settings" -> :match_settings
        "stage-settings" -> :stage_settings
        "brackets-structure" -> :brackets_structure
        "payment-info" -> :payment_info
        "cancel-tournament" -> :cancel_tournament
        _ -> :basic_settings
      end

    socket
    |> assign(:team_site, :settings)
    |> assign(:page, page)
  end

  defp reset_form(socket) do
    socket
    |> assign_tournament_changeset()
    |> assign_discord_sml_changeset()
    |> assign_stream_sml_changesets()
    |> assign_mgmt_changesets()
    |> assign_mgmt_search_results()
    |> assign_stage_setting_changesets()
    |> assign_tiebreaker_strategy_changesets()
    |> assign_brackets_structure_changeset()
  end

  defp valid_changed?(changeset),
    do: (changeset.action == :delete || Enum.any?(changeset.changes)) and changeset.valid?

  defp invalid_changed?(changeset), do: Enum.any?(changeset.changes) and not changeset.valid?
  defp any_valid_changed?(changesets), do: Enum.any?(changesets, &valid_changed?/1)
  defp any_invalid_changed?(changesets), do: Enum.any?(changesets, &invalid_changed?/1)

  defp has_unsaved_changes?(
         tournament_changeset,
         discord_sml_changeset,
         stream_sml_changesets,
         mgmt_changesets,
         stage_setting_changesets,
         tiebreaker_strategy_changesets
       ) do
    flat_stage_setting_changesets =
      stage_setting_changesets
      |> Map.values()
      |> List.flatten()

    anything_valid_changed? =
      valid_changed?(tournament_changeset) or valid_changed?(discord_sml_changeset) or
        any_valid_changed?(stream_sml_changesets) or any_valid_changed?(mgmt_changesets) or
        any_valid_changed?(flat_stage_setting_changesets) or
        any_valid_changed?(tiebreaker_strategy_changesets)

    anything_invalid_changed? =
      invalid_changed?(tournament_changeset) or invalid_changed?(discord_sml_changeset) or
        any_invalid_changed?(stream_sml_changesets) or any_invalid_changed?(mgmt_changesets) or
        any_invalid_changed?(flat_stage_setting_changesets) or
        any_invalid_changed?(tiebreaker_strategy_changesets)

    anything_valid_changed? and not anything_invalid_changed?
  end

  @type saved_socket :: {:cont | :halt, Socket.t()}
  @spec save_changed_valid_changesets(Socket.t()) :: Socket.t()
  defp save_changed_valid_changesets(socket) do
    %{
      tournament_changeset: tournament_changeset,
      discord_sml_changeset: discord_sml_changeset,
      stream_sml_changesets: stream_sml_changesets,
      mgmt_changesets: mgmt_changesets,
      stage_setting_changesets: stage_setting_changesets,
      tiebreaker_strategy_changesets: tiebreaker_strategy_changesets
    } = socket.assigns

    case Strident.TournamentSettings.save_tournament_settings_form(
           tournament_changeset,
           discord_sml_changeset,
           stream_sml_changesets,
           mgmt_changesets,
           stage_setting_changesets,
           tiebreaker_strategy_changesets
         ) do
      {:ok, results} ->
        Logger.info("Updated tournament settings", %{
          user_id: socket.assigns.current_user.id,
          tournament_id: socket.assigns.tournament.id
        })

        socket
        |> SegmentAnalyticsHelpers.track_segment_event("Tournament Settings updated", %{
          tournament_id: socket.assigns.tournament.id
        })
        |> then(
          &if Enum.any?(stage_setting_changesets),
            do:
              SegmentAnalyticsHelpers.track_segment_event(
                &1,
                "Regenerating Tournament because of Settings update",
                %{tournament_id: socket.assigns.tournament.id}
              ),
            else: &1
        )
        |> reassign_tournament(results)
        |> reassign_discord_sml_changeset(results)
        |> reassign_stream_sml_changeset(results)
        |> reassign_mgmt_changeset(results)
        |> reassign_stage_setting_changeset(results)
        |> reassign_tiebreaker_strategy_changesets(results)
        |> put_flash(:info, "Saved")

      {:error, _, error, _} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
  end

  defp reassign_tournament(socket, %{tournament: updated_tournament}) do
    socket
    |> assign(:tournament, updated_tournament)
    |> assign_tournament_changeset()
  end

  defp reassign_tournament(socket, _results), do: socket

  defp reassign_discord_sml_changeset(socket, %{{:delete, :discord_sml} => deleted_sml}) do
    socket
    |> reassign_tournament_with_deleted_sml(deleted_sml)
    |> assign_discord_sml_changeset()
  end

  defp reassign_discord_sml_changeset(socket, %{{:update, :discord_sml} => updated_sml}) do
    socket
    |> reassign_tournament_with_updated_sml(updated_sml)
    |> assign_discord_sml_changeset()
  end

  defp reassign_discord_sml_changeset(socket, %{{:insert, :discord_sml} => inserted_sml}) do
    socket
    |> reassign_tournament_with_inserted_sml(inserted_sml)
    |> assign_discord_sml_changeset()
  end

  defp reassign_discord_sml_changeset(socket, _results), do: socket

  defp reassign_stream_sml_changeset(socket, results) do
    for result <- results, reduce: socket do
      socket ->
        case result do
          {{:delete, {:stream_sml, _}}, deleted_sml} ->
            reassign_tournament_with_deleted_sml(socket, deleted_sml)

          {{:update, {:stream_sml, _}}, updated_sml} ->
            reassign_tournament_with_updated_sml(socket, updated_sml)

          {{:insert, {:stream_sml, _}}, inserted_sml} ->
            reassign_tournament_with_inserted_sml(socket, inserted_sml)

          _ ->
            socket
        end
    end
    |> assign_stream_sml_changesets()
  end

  defp reassign_mgmt_changeset(socket, results) do
    for result <- results, reduce: socket do
      socket ->
        case result do
          {{:delete, {:mgmt, _}}, deleted_mgmt} ->
            reassign_tournament_with_deleted_mgmt(socket, deleted_mgmt)

          {{:insert, {:mgmt, _}}, inserted_mgmt} ->
            reassign_tournament_with_inserted_mgmt(socket, inserted_mgmt)

          _ ->
            socket
        end
    end
    |> assign_mgmt_changesets()
  end

  defp reassign_stage_setting_changeset(socket, results) do
    for result <- results, reduce: socket do
      socket ->
        case result do
          {{:update, {:stage_setting, stage_id, _}}, updated_setting} ->
            reassign_tournament_with_updated_stage_setting(socket, stage_id, updated_setting)

          _ ->
            socket
        end
    end
    |> assign_stage_setting_changesets()
  end

  defp reassign_tiebreaker_strategy_changesets(socket, results) do
    for result <- results, reduce: socket do
      socket ->
        case result do
          {{:update, {:tiebreaker_strategy, _index}}, updated_tiebreaker_strategy} ->
            reassign_tournament_with_updated_tiebreaker_strategy(
              socket,
              updated_tiebreaker_strategy
            )

          _ ->
            socket
        end
    end
    |> assign_tiebreaker_strategy_changesets()
  end

  defp reassign_tournament_with_updated_sml(socket, updated_sml) do
    %{tournament: tournament} = socket.assigns
    index = Enum.find_index(tournament.social_media_links, &(&1.id == updated_sml.id))
    new_smls = List.replace_at(tournament.social_media_links, index, updated_sml)
    new_tournament = %{tournament | social_media_links: new_smls}
    assign(socket, :tournament, new_tournament)
  end

  defp reassign_tournament_with_deleted_sml(socket, deleted_sml) do
    %{tournament: tournament} = socket.assigns
    new_smls = Enum.reject(tournament.social_media_links, &(&1.id == deleted_sml.id))
    new_tournament = %{tournament | social_media_links: new_smls}
    assign(socket, :tournament, new_tournament)
  end

  defp reassign_tournament_with_inserted_sml(socket, inserted_sml) do
    %{tournament: tournament} = socket.assigns
    new_smls = List.insert_at(tournament.social_media_links, -1, inserted_sml)
    new_tournament = %{tournament | social_media_links: new_smls}
    assign(socket, :tournament, new_tournament)
  end

  defp reassign_tournament_with_deleted_mgmt(socket, deleted_mgmt) do
    %{tournament: tournament} = socket.assigns

    new_mgmts = Enum.reject(tournament.management_personnel, &(&1.id == deleted_mgmt.id))

    new_tournament = %{tournament | management_personnel: new_mgmts}
    assign(socket, :tournament, new_tournament)
  end

  defp reassign_tournament_with_inserted_mgmt(socket, inserted_mgmt) do
    %{tournament: tournament} = socket.assigns
    new_mgmts = List.insert_at(tournament.management_personnel, -1, inserted_mgmt)
    new_tournament = %{tournament | management_personnel: new_mgmts}
    assign(socket, :tournament, new_tournament)
  end

  defp reassign_tournament_with_updated_stage_setting(socket, stage_id, updated_stage_setting) do
    %{tournament: tournament} = socket.assigns
    stage_index = Enum.find_index(tournament.stages, &(&1.id == stage_id))
    stage = Enum.at(tournament.stages, stage_index)
    setting_index = Enum.find_index(stage.settings, &(&1.name == updated_stage_setting.name))
    new_settings = List.replace_at(stage.settings, setting_index, updated_stage_setting)
    new_stage = %{stage | settings: new_settings}
    new_stages = List.replace_at(tournament.stages, stage_index, new_stage)
    new_tournament = %{tournament | stages: new_stages}
    assign(socket, :tournament, new_tournament)
  end

  defp reassign_tournament_with_updated_tiebreaker_strategy(socket, updated_tiebreaker_strategy) do
    %{tournament: tournament} = socket.assigns

    stage_index =
      Enum.find_index(tournament.stages, &(&1.id == updated_tiebreaker_strategy.stage_id))

    stage = Enum.at(tournament.stages, stage_index)
    new_stage = %{stage | tiebreaker_strategy: updated_tiebreaker_strategy}
    new_stages = List.replace_at(tournament.stages, stage_index, new_stage)
    new_tournament = %{tournament | stages: new_stages}
    assign(socket, :tournament, new_tournament)
  end

  defp assign_tournament_changeset(socket, attrs \\ %{}) do
    %{tournament: tournament} = socket.assigns

    changeset =
      tournament
      |> Tournament.update_changeset(attrs)
      |> Map.put(:action, :update)

    assign(socket, :tournament_changeset, changeset)
  end

  defp assign_discord_sml_changeset(socket) do
    %{tournament: tournament} = socket.assigns

    user_input =
      tournament.social_media_links
      |> Enum.find(&(&1.brand == :discord))
      |> then(fn
        nil -> ""
        sml -> SocialMediaLink.build_user_input(sml)
      end)

    assign_discord_sml_changeset(socket, user_input)
  end

  defp assign_discord_sml_changeset(socket, user_input) do
    %{tournament: tournament} = socket.assigns

    changeset =
      tournament.social_media_links
      |> Enum.find(&(&1.brand == :discord))
      |> then(fn
        nil -> nil
        sml -> SocialMediaLink.add_user_input(sml)
      end)
      |> SocialMedia.changeset_for_brand_locked_input([:discord, :discordapp], user_input)

    assign(socket, :discord_sml_changeset, changeset)
  end

  defp assign_stream_sml_changesets(socket) do
    %{tournament: tournament} = socket.assigns
    brands = SocialMediaLink.stream_brands()

    stream_sml_changesets =
      tournament.social_media_links
      |> Enum.filter(&(&1.brand in brands))
      |> Enum.map(fn stream_sml ->
        user_input = SocialMediaLink.build_user_input(stream_sml)

        %{stream_sml | user_input: user_input}
        |> SocialMedia.changeset_for_brand_locked_input(brands, user_input)
      end)

    assign(socket, :stream_sml_changesets, stream_sml_changesets)
  end

  defp update_stream_sml_changesets(socket, index, user_input) do
    %{stream_sml_changesets: stream_sml_changesets} = socket.assigns
    brands = SocialMediaLink.stream_brands()

    new_changeset =
      stream_sml_changesets
      |> Enum.at(index)
      |> SocialMedia.changeset_for_brand_locked_input(brands, user_input)

    new_stream_sml_changesets =
      if index < Enum.count(stream_sml_changesets) do
        List.replace_at(stream_sml_changesets, index, new_changeset)
      else
        List.insert_at(stream_sml_changesets, -1, new_changeset)
      end

    assign(socket, :stream_sml_changesets, new_stream_sml_changesets)
  end

  defp add_stream_sml_changeset(socket) do
    %{stream_sml_changesets: stream_sml_changesets} = socket.assigns
    brands = SocialMediaLink.stream_brands()

    new_stream_sml_changesets =
      nil
      |> SocialMedia.changeset_for_brand_locked_input(brands, "")
      |> then(&List.insert_at(stream_sml_changesets, -1, &1))

    assign(socket, :stream_sml_changesets, new_stream_sml_changesets)
  end

  defp remove_stream_sml_changeset(socket, index) do
    %{stream_sml_changesets: stream_sml_changesets} = socket.assigns

    new_stream_sml_changesets =
      case Enum.at(stream_sml_changesets, index) do
        %{action: :update} ->
          List.update_at(stream_sml_changesets, index, &%{&1 | action: :delete})

        %{action: :insert} ->
          List.delete_at(stream_sml_changesets, index)
      end

    assign(socket, :stream_sml_changesets, new_stream_sml_changesets)
  end

  defp assign_mgmt_changesets(socket) do
    %{tournament: tournament} = socket.assigns

    mgmt_changesets =
      tournament.management_personnel
      |> Enum.map(&TournamentManagementPersonnel.changeset/1)

    assign(socket, :mgmt_changesets, mgmt_changesets)
  end

  defp add_mgmt_changeset(socket, user_id) do
    %{
      tournament: tournament,
      mgmt_changesets: mgmt_changesets,
      mgmt_search_results: mgmt_search_results
    } = socket.assigns

    user = Enum.find(mgmt_search_results, &(&1.id == user_id))

    new_mgmt_changesets =
      %TournamentManagementPersonnel{user: user}
      |> TournamentManagementPersonnel.changeset(%{tournament_id: tournament.id, user_id: user_id})
      |> Map.put(:action, :insert)
      |> then(&List.insert_at(mgmt_changesets, -1, &1))

    socket
    |> assign(:mgmt_changesets, new_mgmt_changesets)
    |> assign_mgmt_search_results()
  end

  defp remove_mgmt_changeset(socket, index) do
    %{mgmt_changesets: mgmt_changesets} = socket.assigns

    new_mgmt_changesets =
      case Enum.at(mgmt_changesets, index) do
        %{action: :insert} ->
          List.delete_at(mgmt_changesets, index)

        _ ->
          List.update_at(mgmt_changesets, index, &%{&1 | action: :delete})
      end

    assign(socket, :mgmt_changesets, new_mgmt_changesets)
  end

  defp assign_mgmt_search_results(socket) do
    assign(socket, :mgmt_search_results, [])
  end

  defp search_users_for_mgmt(socket, user_input) do
    mgmt_search_results =
      if String.length(user_input) > 2, do: Search.search_users(user_input), else: []

    assign(socket, :mgmt_search_results, mgmt_search_results)
  end

  defp assign_stage_setting_changesets(socket) do
    %{tournament: %{stages: stages}} = socket.assigns

    stage_setting_changesets =
      Enum.reduce(stages, %{}, fn stage, acc ->
        stage.settings
        |> Enum.map(&StageSetting.changeset(&1, %{}))
        |> then(&Map.put(acc, stage.id, &1))
      end)

    assign(socket, :stage_setting_changesets, stage_setting_changesets)
  end

  defp update_stage_setting_changesets(socket, unsafe_stage_id, index, value) do
    %{tournament: tournament, stage_setting_changesets: stage_setting_changesets} = socket.assigns
    known_stage = Enum.find(tournament.stages, &(&1.id == unsafe_stage_id))
    %{id: stage_id} = known_stage
    changesets = Map.get(stage_setting_changesets, stage_id)

    new_changeset =
      changesets
      |> Enum.at(index)
      |> ChangesetUtils.clean_changeset_errors()
      |> StageSetting.changeset(%{value: value})

    new_changesets =
      if index < Enum.count(changesets) do
        List.replace_at(changesets, index, new_changeset)
      else
        List.insert_at(changesets, -1, new_changeset)
      end

    new_stage_setting_changesets = Map.put(stage_setting_changesets, stage_id, new_changesets)

    assign(socket, :stage_setting_changesets, new_stage_setting_changesets)
  end

  defp assign_tiebreaker_strategy_changesets(socket) do
    %{tournament: %{stages: stages}} = socket.assigns

    tiebreaker_strategy_changesets =
      Enum.map(stages, &TiebreakerStrategy.changeset(&1.tiebreaker_strategy, %{}))

    assign(socket, :tiebreaker_strategy_changesets, tiebreaker_strategy_changesets)
  end

  defp update_tiebreaker_strategy_changesets(socket, unsafe_stage_id, steps) do
    %{tournament: tournament, tiebreaker_strategy_changesets: changesets} = socket.assigns
    known_stage = Enum.find(tournament.stages, &(&1.id == unsafe_stage_id))
    %{id: stage_id} = known_stage
    index = Enum.find_index(changesets, &(&1.data.stage_id == stage_id))
    changeset = changesets |> Enum.at(index) |> ChangesetUtils.clean_changeset_errors()

    steps =
      steps
      |> Enum.take_while(&(&1 != :manual))
      |> then(&(&1 ++ [:manual]))

    new_changeset = TiebreakerStrategy.changeset(changeset, %{type: steps})

    new_changesets =
      if index < Enum.count(changesets) do
        List.replace_at(changesets, index, new_changeset)
      else
        List.insert_at(changesets, -1, new_changeset)
      end

    assign(socket, :tiebreaker_strategy_changesets, new_changesets)
  end
end
