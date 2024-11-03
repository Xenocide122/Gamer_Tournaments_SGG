defmodule StridentWeb.TournamentLive.Create.TournamentInfo do
  @moduledoc """
  The "tournament info" form page, where user provides details.
  """
  use StridentWeb, :live_component

  alias Strident.DraftForms.CreateTournament.TournamentInfo
  alias Strident.PrizeLogic
  alias Strident.Prizes
  alias StridentWeb.Common.MoneyInput

  @impl true
  def mount(socket) do
    socket
    |> assign(:simplify_prize_recommendation, true)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(
        %{
          f: f,
          tournament_type: tournament_type,
          stages_structure: stages_structure,
          tournament_info: tournament_info,
          stages: stages,
          games: games,
          platforms: platforms,
          prize_strategies: prize_strategies,
          locations: locations,
          ip_location: ip_location
        } = assigns,
        socket
      ) do
    platforms = platforms |> Enum.map(&{elem(&1, 1), elem(&1, 0)}) |> Enum.sort_by(&elem(&1, 0))

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:f, f)
    |> assign(:games, games)
    |> assign(:ip_location, ip_location)
    |> assign(
      :games_selection,
      games |> Enum.map(&{&1.title, &1.id}) |> Enum.sort_by(&elem(&1, 0))
    )
    |> assign(:platforms, platforms)
    |> assign(:prize_strategies, prize_strategies)
    |> assign(:locations, locations)
    |> assign(:tournament_type, tournament_type)
    |> assign(:stages_structure, stages_structure)
    |> assign(:tournament_info, tournament_info)
    |> assign(:stages, stages)
    |> assign(:grilla_cut, PrizeLogic.grilla_cut_as_rounded_percent())
    |> assign_tournament_description()
    |> then(&{:ok, &1})
  end

  def assign_tournament_description(%{assigns: %{stages_structure: stages_structure}} = socket) do
    tournament_description =
      case stages_structure do
        :single_elimination ->
          "This is the classic tournament experience. Winners move on to the next round, losers type \"GG's\" in the chat and move to spectator mode."

        :double_elimination ->
          "The most common twist on the classic tournament. Participants start in the upper bracket.
          A loss gets you sent down to the lower bracket, with one last chance for redemption. Two losses though, and you can watch the rest of the stream from your couch.
                                                      "

        :round_robin ->
          "The best option for small groups or big leagues. Everyone gets a game against everyone to prove who is top dog.
                                                      You fill out the basics, we take care of the rest (even the tie breaks)!"

        :swiss ->
          " Have a huge group of players and not enough time for them to square off with everyone else? That's where Swiss system steps in!
                                          Each round, participants play against opponents of their same skill level. The cream always rises to the top. You fill out the basics, we take care of the rest (even byes)!"

        _ ->
          nil
      end

    assign(socket, :tournament_description, tournament_description)
  end
end
