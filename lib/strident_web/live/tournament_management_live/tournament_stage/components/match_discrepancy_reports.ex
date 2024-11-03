defmodule StridentWeb.TournamentStage.Components.MatchDiscrepancyReports do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Matches
  alias Strident.TournamentParticipants

  @impl true
  def render(assigns) do
    ~H"""
    <section class="mt-8">
      <%= for %{participants: [mp_0, mp_1]} = match <- @matches_with_discrepancy_reports do %>
        <div class="rounded bg-secondary shadow-md shadow-secondary p-[1px]">
          <div class="rounded bg-blackish py-[8px] lg:px-3">
            <div class="flex items-center justify-center">
              <svg
                width="40"
                height="40"
                viewBox="0 0 24 24"
                class="mr-2 stroke-secondary fill-none"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d={StridentWeb.Common.SvgUtils.path(:exclamation)}
                />
              </svg>
              <h3 class="uppercase text-secondary">
                Player Reported Scores Do Not Match
              </h3>
            </div>

            <div class="py-4 text-center px-9 text-grey-light">
              The scores reported for the match between <%= TournamentParticipants.participant_name(
                mp_0.tournament_participant
              ) %> and <%= TournamentParticipants.participant_name(mp_1.tournament_participant) %> do not match, please manually enter the score to continue.
            </div>

            <div class="flex flex-col items-center justify-center mt-16 mb-4">
              <%= for reported_score <- match.match_reports, participant <- match.participants, reported_score.match_participant_id == participant.id do %>
                <div class="mt-2 text-xl">
                  <%= TournamentParticipants.participant_name(participant.tournament_participant) %> Reported Score:
                </div>

                <div class="flex items-center justify-center mt-4">
                  <p class="mr-2 text-3xl text-center">
                    <%= return_participant_for_reported_score(
                      reported_score.reported_score,
                      match.participants
                    )
                    |> TournamentParticipants.participant_name() %>
                  </p>
                  <img
                    src={
                      return_participant_for_reported_score(
                        reported_score.reported_score,
                        match.participants
                      )
                      |> TournamentParticipants.participant_logo_url()
                    }
                    alt=""
                    width="50"
                    height="50"
                    class="mr-2 rounded-full"
                  />
                  <p class="text-3xl font-bold">
                    <%= return_score_for_reported_score(reported_score.reported_score) %>
                  </p>

                  <p class="hidden mx-4 text-3xl font-bold md:block text-grey-light">-</p>

                  <p class="text-3xl font-bold">
                    <%= return_score_for_reported_score(reported_score.reported_score, 1) %>
                  </p>

                  <img
                    src={
                      return_participant_for_reported_score(
                        reported_score.reported_score,
                        match.participants,
                        1
                      )
                      |> TournamentParticipants.participant_logo_url()
                    }
                    alt=""
                    width="50"
                    height="50"
                    class="ml-2 rounded-full"
                  />
                  <p class="ml-2 text-3xl text-center">
                    <%= return_participant_for_reported_score(
                      reported_score.reported_score,
                      match.participants,
                      1
                    )
                    |> TournamentParticipants.participant_name() %>
                  </p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </section>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{matches: matches} = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:matches, matches)
    |> assign_matches_with_discrepancy_reports()
    |> then(&{:ok, &1})
  end

  defp assign_matches_with_discrepancy_reports(socket) do
    %{assigns: %{matches: matches}} = socket

    matches_with_discrepancy_reports =
      Enum.reduce(matches, [], fn match, matches ->
        %{participants: participants, match_reports: match_reports} =
          Matches.get_match_with_preloads(match)

        if Enum.count(participants) == Enum.count(match_reports) and
             Enum.any?(participants, &(is_nil(&1.score) or is_nil(&1.rank))) do
          [match | matches]
        else
          matches
        end
      end)

    assign(socket, :matches_with_discrepancy_reports, matches_with_discrepancy_reports)
  end

  defp return_participant_for_reported_score(reported_score, participants, index \\ 0) do
    reported_score
    |> Map.to_list()
    |> Enum.at(index)
    |> elem(0)
    |> then(&Enum.find(participants, fn %{id: id} -> id == &1 end))
    |> Map.get(:tournament_participant)
  end

  defp return_score_for_reported_score(reported_score, index \\ 0) do
    reported_score |> Map.to_list() |> Enum.at(index) |> elem(1)
  end
end
