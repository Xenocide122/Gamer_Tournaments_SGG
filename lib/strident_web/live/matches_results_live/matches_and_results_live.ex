defmodule StridentWeb.MatchesAndResultsLive do
  @moduledoc """
  The "Matches & Results" page that a tournament organizer (TO) can see.

  TODO https://xd.adobe.com/view/7bd63a26-c897-4754-adf2-a26db7e54eee-2e85/screen/4914a3d1-05ad-4a95-9464-01ca172bc171/
  """
  require Logger
  use StridentWeb, :live_view
  alias Strident.BijectiveHexavigesimal
  alias Strident.Matches
  alias Strident.Matches.Match
  alias Strident.MatchParticipants
  alias Strident.MatchParticipants.MatchParticipant
  alias Strident.MatchReports
  alias Strident.Stages.Stage
  alias Strident.Tournaments
  alias StridentWeb.TournamentManagment.Setup
  alias StridentWeb.TournamentParticipants.TournamentParticipantsHelpers

  on_mount({StridentWeb.InitAssigns, :default})
  on_mount({Setup, :full})
  on_mount({Setup, :can_manage_tournament})

  @impl true
  def render(assigns) do
    assigns =
      Map.merge(assigns, %{
        td_class: "py-2",
        grid_container_class:
          "w-full rounded-md p-px bg-gradient-to-l from-[#03d5fb] to-[#ff6802]"
      })

    ~H"""
    <.container id={"tournament-matches-and-results-#{@tournament.id}"}>
      <:side_menu>
        <.live_component
          id={"side-menu-#{@tournament.id}"}
          module={StridentWeb.TournamentManagement.Components.SideMenu}
          can_manage_tournament={@can_manage_tournament}
          tournament={@tournament}
          number_of_participants={
            Enum.count(@tournament.participants, &(&1.status in Tournaments.on_track_statuses()))
          }
          current_user={@current_user}
          live_action={@current_menu_item}
          timezone={@timezone}
          locale={@locale}
        />
      </:side_menu>

      <div class="px-4 md:px-32">
        <h3 class="hidden mb-6 leading-none tracking-normal uppercase md:block font-display">
          Matches & Results
        </h3>

        <.form
          :let={f}
          for={@form_matches_filter}
          id="bracket-seeding-matches-filter-form"
          phx-change="change-matches-filter"
          class="flex flex-col md:flex-row gap-x-20"
        >
          <%= select(f, :stage_id, @matches_filter_options.stage_id,
            value: @matches_filter.stage_id,
            class: "form-input mb-4",
            phx_debounce: "200"
          ) %>
          <%= select(f, :round, @matches_filter_options.round,
            value: @matches_filter.round,
            class: "form-input mb-4",
            phx_debounce: "200"
          ) %>
          <%= select(f, :type, @matches_filter_options.type,
            value: @matches_filter.type,
            class: "form-input mb-4",
            phx_debounce: "200"
          ) %>
        </.form>

        <div class={@grid_container_class}>
          <div class="grid w-full grid-cols-2 py-2 text-center divide-x rounded-md bg-blackish divide-grey-light">
            <div class="flex justify-center">
              <div>
                <h3 class="align-center">
                  <%= Enum.count(@displayed_match_details) %>
                </h3>
                <div class="text-grey-light align-center">
                  Matches
                </div>
              </div>
            </div>
            <div class="flex justify-center">
              <div>
                <h3 class="align-center">
                  <%= Enum.count(@displayed_match_details, &Matches.is_match_finished?(&1.match)) %>
                </h3>
                <div class="text-grey-light align-center">
                  Completed
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          :for={
            %{
              match: match,
              label: label,
              reported_scores: reported_scores,
              reports_agree: reports_agree,
              can_accept_score: can_accept_score,
              can_edit_score: can_edit_score
            } <-
              @displayed_match_details
          }
          id={"match-summary-#{match.id}"}
          class="my-3"
        >
          <table id={"match-summary-table-#{match.id}"} class="w-full font-light rounded table-fixed">
            <thead class="bg-grey-medium text-grey-light">
              <th class="w-5/12 py-2 pl-6 font-light text-left text-white">
                <div class="flex items-center gap-x-2">
                  <.svg
                    :if={can_edit_score or can_accept_score}
                    icon={:exclamation}
                    width="24"
                    height="24"
                    class="text-secondary"
                  />
                  <p>Match <%= label %></p>
                </div>
              </th>
              <th class="py-2 font-light text-left">Score</th>
              <th class="py-2 font-light text-left">Screenshot</th>
              <th class="py-2 font-light text-left">Video</th>
              <th class="w-32 py-2 pr-6 font-light text-left">Status</th>
            </thead>
            <tbody class="divide-y bg-blackish gap-y-4 divide-grey">
              <tr :for={mp <- match.participants} class="items-center">
                <td class={["pl-6", @td_class]}>
                  <div class="flex items-center gap-x-2">
                    <.image
                      id={"match-participant-logo-#{mp.id}"}
                      image_url={Map.get(@participant_details, mp.tournament_participant_id).logo_url}
                      alt={Map.get(@participant_details, mp.tournament_participant_id).name}
                      class="rounded-full"
                      width={20}
                      height={20}
                    />
                    <div class={[if(mp.rank == 0, do: "text-primary")]}>
                      <%= Map.get(@participant_details, mp.tournament_participant_id).name %>
                    </div>
                  </div>
                </td>
                <td class={["text-center", @td_class]}>
                  <div
                    :if={!mp.score and !reports_agree}
                    class="uppercase text-secondary whitespace-nowrap"
                  >
                    Scores do not match
                  </div>
                  <div :if={!mp.score and reports_agree}>
                    <%= reported_score(reported_scores, mp.id) %>
                  </div>
                  <div :if={mp.score}>
                    <%= mp.score %>
                  </div>
                </td>
                <td class={["text-center", @td_class]}>View</td>
                <td class={["text-center", @td_class]}>Link</td>
                <td id={"mp-status-#{mp.id}"} class={["text-center items-center pr-6", @td_class]}>
                  <%= status(match, mp) %>
                </td>
              </tr>
            </tbody>
          </table>
          <div
            :if={can_edit_score or can_accept_score}
            class="flex justify-center py-6 bg-grey-medium gap-x-4"
          >
            <.edit_score_modal
              :if={can_edit_score}
              match={match}
              label={label}
              participant_details={@participant_details}
            />
            <.button
              :if={can_accept_score}
              id={"accept-incomplete-reported-scores-#{match.id}"}
              button_type={:primary}
              class="uppercase rounded py-1.5"
              phx-click="accept-underreported-score"
              phx-value-match-id={match.id}
            >
              Accept score
            </.button>
          </div>
        </div>

        <.live_component
          :if={@show_confirmation}
          id="matches-and-results-confirmation"
          module={StridentWeb.Components.Confirmation}
          confirm_event={@confirmation_confirm_event}
          confirm_values={@confirmation_confirm_values}
          message={@confirmation_message}
          confirm_prompt={@confirmation_confirm_prompt}
          cancel_prompt={@confirmation_cancel_prompt}
          timezone={@timezone}
          locale={@locale}
        />
      </div>
    </.container>
    """
  end

  attr(:match, :any, required: true)
  attr(:label, :string, required: true)
  attr(:participant_details, :map, required: true)
  attr(:form_scores, :any, default: to_form(%{}, as: :scores))

  defp edit_score_modal(assigns) do
    assigns = Map.merge(assigns, %{td_class: "py-2"})

    ~H"""
    <div class="relative">
      <.button
        id={"edit-incomplete-reported-scores-#{@match.id}"}
        phx-click={show_modal("edit-incomplete-reported-scores-modal-#{@match.id}")}
        class="border-primary text-white bg-blackish uppercase rounded py-1.5"
      >
        Edit score
      </.button>
      <.modal
        id={"edit-incomplete-reported-scores-modal-#{@match.id}"}
        modal_size="modal__dialog--large"
      >
        <:header>
          <h3>
            Match <%= @label %> - Edit Score
          </h3>
        </:header>
        <div>
          <.form :let={f} for={@form_scores} phx-submit="edit-incomplete-reported-scores">
            <%= hidden_input(f, :match_id, value: @match.id, id: "hidden-match-id-input-#{@match.id}") %>
            <%= hidden_input(f, :stage_id,
              value: @match.stage_id,
              id: "hidden-stage-id-input-#{@match.id}"
            ) %>
            <table
              id={"edit-incomplete-reported-scores-table-#{@match.id}"}
              class="w-full font-light rounded table-fixed"
            >
              <thead class="bg-grey-medium text-grey-light">
                <th class="py-2 font-light text-left"></th>
                <th :for={report <- @match.match_reports} class="py-2 font-light text-left">
                  <%= Map.get(
                    @participant_details,
                    Enum.find(@match.participants, &(&1.id == report.match_participant_id)).tournament_participant_id
                  ).name %> Reported
                </th>
                <th class="py-2 font-light text-left">Screenshot</th>
                <th class="py-2 font-light text-left">Video</th>
                <th class="w-32 py-2 pr-6 font-light text-left">Score</th>
              </thead>
              <tbody class="divide-y bg-blackish gap-y-4 divide-grey">
                <tr :for={mp <- @match.participants} class="items-center">
                  <td class={["pl-6", @td_class]}>
                    <div class="flex items-center gap-x-2">
                      <.image
                        id={"edit-incomplete-reported-scores-match-participant-logo-#{mp.id}"}
                        image_url={
                          Map.get(@participant_details, mp.tournament_participant_id).logo_url
                        }
                        alt={Map.get(@participant_details, mp.tournament_participant_id).name}
                        class="rounded-full"
                        width={20}
                        height={20}
                      />
                      <div>
                        <%= Map.get(@participant_details, mp.tournament_participant_id).name %>
                      </div>
                    </div>
                  </td>
                  <td :for={report <- @match.match_reports} class="py-2 font-light text-left">
                    <%= Map.get(report.reported_score, mp.id) %>
                  </td>
                  <td class={["text-center", @td_class]}>View</td>
                  <td class={["text-center", @td_class]}>Link</td>
                  <td
                    id={"edit-incomplete-reported-scores-mp-score-input-#{mp.id}"}
                    class={["text-center items-center pr-6", @td_class]}
                  >
                    <.form_text_input
                      id={"mp-score-input-#{mp.id}"}
                      form={f}
                      field={mp.id}
                      class="w-20 h-full font-normal text-center form-input border-primary"
                      type="text"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
            <div class="flex justify-center py-6 bg-grey-medium gap-x-4">
              <.button
                id={"exit-scores-modal-#{@match.id}"}
                class="border-primary text-white bg-blackish uppercase rounded py-1.5"
                phx-click={hide_modal("edit-incomplete-reported-scores-modal-#{@match.id}")}
                type="button"
              >
                Cancel
              </.button>
              <.button
                id={"save-scores-#{@match.id}"}
                button_type={:primary}
                class="rounded py-1.5"
                type="submit"
              >
                Save Scores
              </.button>
            </div>
          </.form>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:form_matches_filter, to_form(%{}, as: :matches_filter))
    |> close_confirmation()
    |> assign(:show_confirmation, false)
    |> assign(:current_menu_item, :matches_and_results)
    |> TournamentParticipantsHelpers.assign_participant_details()
    |> assign_match_labels()
    |> assign(:matches_filter, %{})
    |> assign_matches_filter_options()
    |> assign_displayed_match_details()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(params, _session, socket) do
    %{tournament: tournament, matches_filter: _matches_filter} = socket.assigns

    case params do
      %{"type" => type, "round" => round, "stage_id" => stage_id}
      when is_binary(type) and is_binary(round) and is_binary(stage_id) ->
        selected_type = String.to_existing_atom(type)
        selected_stage = Enum.find(tournament.stages, &(&1.id == stage_id))

        if selected_stage do
          integer_round = String.to_integer(round)

          selected_round =
            if !!selected_stage && Enum.any?(selected_stage.matches, &(&1.round == integer_round)) do
              integer_round
            else
              0
            end

          matches_filter = %{
            type: selected_type,
            round: selected_round,
            stage_id: selected_stage.id
          }

          socket
          |> assign(:matches_filter, matches_filter)
          |> assign_matches_filter_options()
          |> assign_displayed_match_details()
        else
          socket
        end

      _ ->
        socket
    end
    |> then(&{:noreply, &1})
  end

  defp assign_match_labels(socket) do
    %{tournament: tournament} = socket.assigns

    match_labels =
      for stage <- tournament.stages, reduce: %{} do
        match_labels ->
          {match_labels, _prev_index} =
            for match <- Enum.sort_by(stage.matches, & &1.round), reduce: {match_labels, -1} do
              {match_labels, prev_index} ->
                index = prev_index + 1
                name = BijectiveHexavigesimal.to_az_string(index)
                new_match_labels = Map.put(match_labels, match.id, name)
                {new_match_labels, index}
            end

          match_labels
      end

    assign(socket, :match_labels, match_labels)
  end

  defp assign_matches_filter_options(socket) do
    %{tournament: tournament, matches_filter: matches_filter} = socket.assigns

    stage_options =
      tournament.stages
      |> Enum.sort_by(& &1.round)
      |> Enum.map(&{stage_option_label(&1), &1.id})

    default_stage_id =
      if Enum.any?(tournament.stages) do
        List.first(tournament.stages).id
      else
        nil
      end

    stage_id = Map.get(matches_filter, :stage_id, default_stage_id)
    selected_stage = Enum.find(tournament.stages, &(&1.id == stage_id))

    allowed_rounds =
      if selected_stage do
        selected_stage.matches
        |> Enum.map(& &1.round)
        |> Enum.uniq()
        |> Enum.sort()
      else
        []
      end

    round_options = Enum.map(allowed_rounds, &{"Round #{&1 + 1}", &1})

    type_options =
      if selected_stage do
        selected_stage.matches
        |> Enum.map(& &1.type)
        |> Enum.uniq()
        |> Enum.sort_by(&if &1 == :upper, do: 0, else: 1)
      else
        []
      end

    matches_filter_options = %{
      type: type_options,
      round: round_options,
      stage_id: stage_options
    }

    socket
    |> assign(:matches_filter_options, matches_filter_options)
    |> update(:matches_filter, fn matches_filter ->
      update_matches_filter(matches_filter, stage_id, allowed_rounds, type_options)
    end)
  end

  defp update_matches_filter(matches_filter, stage_id, allowed_rounds, type_options) do
    # ensure all keys are present, with sane default values
    matches_filter
    |> then(fn
      %{stage_id: ^stage_id} -> matches_filter
      _ -> Map.put(matches_filter, :stage_id, stage_id)
    end)
    |> then(fn matches_filter ->
      if Map.get(matches_filter, :round) in allowed_rounds do
        matches_filter
      else
        Map.put(matches_filter, :round, List.first(allowed_rounds))
      end
    end)
    |> then(fn matches_filter ->
      if Map.get(matches_filter, :type) in type_options do
        matches_filter
      else
        Map.put(matches_filter, :type, List.first(type_options))
      end
    end)
  end

  defp stage_option_label(%Stage{} = stage) do
    "Stage #{stage.round + 1} - #{Phoenix.Naming.humanize(stage.type)}"
  end

  defp assign_displayed_match_details(socket) do
    %{tournament: tournament, matches_filter: matches_filter, match_labels: match_labels} =
      socket.assigns

    %{type: type, round: round, stage_id: stage_id} = matches_filter
    selected_stage = Enum.find(tournament.stages, &(&1.id == stage_id))

    displayed_match_details =
      if selected_stage do
        displayed_matches =
          Enum.filter(
            selected_stage.matches,
            &(&1.round == round and &1.type == type and Enum.count(&1.participants) > 1)
          )

        Enum.map(displayed_matches, &match_to_details_map(&1, match_labels))
      else
        []
      end

    assign(socket, :displayed_match_details, displayed_match_details)
  end

  defp match_to_details_map(match, match_labels) do
    any_scores = Enum.any?(match.participants, & &1.score)

    reported_scores =
      MatchReports.build_reported_integer_scores_by_participant_id(match.match_reports)

    reports_agree =
      not Enum.any?(reported_scores, fn {_mp_id, scores} -> Enum.count(scores) > 1 end)

    can_accept_score = Enum.any?(reported_scores) and reports_agree and not any_scores
    # hack
    # can_edit_score = Enum.any?(reported_scores) and not any_scores
    can_edit_score = true

    label = Map.get(match_labels, match.id, match.id)

    %{
      match: match,
      label: label,
      reported_scores: reported_scores,
      reports_agree: reports_agree,
      can_accept_score: can_accept_score,
      can_edit_score: can_edit_score
    }
  end

  defp reported_score(reported_scores, mp_id) do
    reported_scores |> Map.get(mp_id, []) |> List.first()
  end

  @type score_report_status :: :waiting | :score_reported | :awaiting_score | :complete
  @spec score_report_status(Match.t(), MatchParticipant.t()) :: score_report_status()
  defp score_report_status(match, mp) do
    cond do
      Enum.all?(match.participants, & &1.score) -> :complete
      Enum.any?(match.match_reports, &(&1.match_participant_id == mp.id)) -> :score_reported
      MatchReports.any_reported?(match) -> :awaiting_score
      true -> :waiting
    end
  end

  @spec score_report_status_label(score_report_status()) :: String.t()
  defp score_report_status_label(status_atom) do
    case status_atom do
      :waiting -> "Waiting"
      :score_reported -> "Score Reported"
      :awaiting_score -> "Awaiting Score"
      :complete -> "Complete"
    end
  end

  defp status(match, mp) do
    status_atom = score_report_status(match, mp)
    label = score_report_status_label(status_atom)

    status_specific_class =
      case status_atom do
        :waiting -> "bg-grey-light text-black px-4"
        :score_reported -> "border border-primary text-white px-2"
        :awaiting_score -> "border border-secondary text-white px-2"
        :complete -> "bg-primary text-black px-4"
      end

    assigns = %{label: label, status_specific_class: status_specific_class}

    ~H"""
    <div class="flex justify-center">
      <div class={["rounded-full text-xs ellipsis whitespace-nowrap", @status_specific_class]}>
        <%= @label %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("change-matches-filter", %{"matches_filter" => filter_params}, socket) do
    %{tournament: tournament, matches_filter: _matches_filter} = socket.assigns

    case filter_params do
      %{"type" => type, "round" => round, "stage_id" => stage_id}
      when is_binary(type) and is_binary(round) and is_binary(stage_id) ->
        push_patch(socket,
          to:
            Routes.tournament_matches_and_results_path(socket, :index, tournament.slug,
              stage_id: stage_id,
              round: round,
              type: type
            )
        )

      _ ->
        put_flash(socket, :error, "Something went wrong. Please refresh the page.")
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("edit-incomplete-reported-scores", params, socket) do
    %{"scores" => scores_with_match_id_and_stage_id} = params
    %{"match_id" => match_id, "stage_id" => stage_id} = scores_with_match_id_and_stage_id
    scores = Map.drop(scores_with_match_id_and_stage_id, ["match_id", "stage_id"])

    socket
    |> bulk_update(match_id, stage_id, scores)
    |> then(&{:noreply, &1})
  end

  def handle_event("accept-underreported-score", params, socket) do
    %{"match-id" => match_id} = params
    %{displayed_match_details: displayed_match_details} = socket.assigns

    match_detail = Enum.find(displayed_match_details, &(&1.match.id == match_id))
    %{match: match, reported_scores: reported_scores} = match_detail

    scores =
      Enum.reduce(match.participants, %{}, fn mp, acc ->
        score = reported_score(reported_scores, mp.id)
        Map.put(acc, mp.id, to_string(score))
      end)

    socket
    |> bulk_update(match.id, match.stage_id, scores)
    |> then(&{:noreply, &1})
  end

  defp bulk_update(socket, match_id, stage_id, scores) do
    with {:ok, mp_attrs_list_without_ranks} <- build_init_mp_attrs_list(scores),
         {:ok, mp_attrs_list} <- assume_ranks(mp_attrs_list_without_ranks),
         {:ok, list_of_updated_mps} <-
           MatchParticipants.bulk_update_mps(mp_attrs_list) do
      socket
      |> put_flash(:info, "Updated scores")
      |> update(:tournament, fn tournament ->
        updated_stages =
          Enum.map(tournament.stages, fn stage ->
            if stage.id == stage_id do
              updated_matches =
                Enum.map(stage.matches, fn match ->
                  if match.id == match_id do
                    updated_participants =
                      Enum.map(match.participants, fn mp ->
                        case Enum.find(list_of_updated_mps, &(&1.id == mp.id)) do
                          nil -> mp
                          updated_mp -> %{mp | rank: updated_mp.rank, score: updated_mp.score}
                        end
                      end)

                    %{match | participants: updated_participants}
                  else
                    match
                  end
                end)

              %{stage | matches: updated_matches}
            else
              stage
            end
          end)

        %{tournament | stages: updated_stages}
      end)
      |> assign_displayed_match_details()
    else
      {:error, error} ->
        socket
        |> put_string_or_changeset_error_in_flash(error)
    end
  end

  defp build_init_mp_attrs_list(scores) do
    Enum.reduce_while(scores, {:ok, []}, fn {mp_id, score}, {:ok, acc} ->
      case Integer.parse(score) do
        {integer_score, ""} ->
          {:cont, {:ok, [%{id: mp_id, score: score, integer_score: integer_score} | acc]}}

        _ ->
          {:halt, {:error, "Scores must be integers"}}
      end
    end)
  end

  defp assume_ranks(mp_attrs_list_without_ranks) do
    mp_attrs_list_without_ranks
    |> Enum.group_by(& &1.integer_score)
    |> Enum.sort_by(fn {int_score, _attrs_list} -> int_score end, :desc)
    |> Enum.with_index()
    |> Enum.flat_map(fn {{_int_score, attrs_list}, assumed_rank} ->
      Enum.map(attrs_list, fn mp_attrs ->
        Map.put(mp_attrs, :rank, assumed_rank)
      end)
    end)
    |> then(&{:ok, &1})
  end
end
