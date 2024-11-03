defmodule StridentWeb.TournamentSettingsLive.Components.StageSettings do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Stages.StageSetting
  alias Strident.Tiebreaking

  @form_labels %{
    number_times_players_meet: "Matches Against Opponents",
    number_groups: "Number of Groups",
    number_rounds: "Number of Rounds",
    do_randomize_pairings: "Pairings",
    match_games: "Match Format",
    final_games: "Finals Match Format",
    has_first_round_losers: "First Round",
    do_finals_reset: "Reset Grand Final if loser's first loss?",
    points_per_score: "Points per Game",
    number_to_advance_per_group: "Number of Participants per Group that Advance",
    number_upper_to_advance_per_group:
      "Number of Participants per Group that Advance to Upper Bracket",
    number_lower_to_advance_per_group:
      "Number of Participants per Group that Advance to Lower Bracket",
    number_to_advance: "Number of Participants that Advance",
    number_upper_to_advance: "Number of Participants that Advance to Upper Bracket",
    number_lower_to_advance: "Number of Participants that Advance to Lower Bracket"
  }

  @sort_order [
    :match_games,
    :do_finals_reset,
    :final_games,
    :has_first_round_losers,
    :number_times_players_meet,
    :number_groups,
    :number_rounds,
    :do_randomize_pairings,
    :points_per_score,
    :points_per_match,
    :points_per_bye,
    :number_to_advance_per_group,
    :number_upper_to_advance_per_group,
    :number_lower_to_advance_per_group,
    :number_to_advance,
    :number_upper_to_advance,
    :number_lower_to_advance
  ]
  defp sort_order(name), do: Enum.find_index(@sort_order, &(&1 == name))

  @tiebreak_copy %{
    playoff: "Playoff Match",
    manual: "Manual Tie Break",
    wins_vs_tied: "Wins vs Tied Participants",
    game_wins: "Game/Set Wins",
    median_bucholz: "Median-Bucholz System"
  }

  @impl true
  def update(
        %{
          tournament: tournament,
          stage_setting_changesets: stage_setting_changesets,
          tiebreaker_strategy_changesets: tiebreaker_strategy_changesets
        },
        socket
      ) do
    socket
    |> assign(:is_connected, connected?(socket))
    |> assign(:cancelled, tournament.status == :cancelled)
    |> assign(:tournament, tournament)
    |> assign(:stage_setting_changesets, stage_setting_changesets)
    |> assign(:tiebreaker_strategy_changesets, tiebreaker_strategy_changesets)
    |> then(&{:ok, &1})
  end

  defp get_stage_setting_html_value_from_changeset(changeset) do
    case Ecto.Changeset.get_field(changeset, :value) do
      %{t: _type, v: value} -> value
      {value, _type} -> value
    end
  end

  defp selected_for_select_with_custom_input(changeset, name) do
    changeset_value = get_stage_setting_html_value_from_changeset(changeset)
    options = get_select_options(name)

    case Enum.find(options, fn {_key, value} -> value == changeset_value end) do
      {_key, value} -> value
      _ -> :enable_custom_input
    end
  end

  defp capitalize_each_word(atom) do
    atom
    |> humanize()
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @spec tiebreak_possibilities([atom()], atom()) :: [{atom(), [atom()]}]
  defp tiebreak_possibilities(tiebreakers, stage_type) do
    possibles =
      Tiebreaking.strategies_for_type(stage_type)
      |> Enum.map(&get_tiebreak_select/1)

    Enum.map_reduce(tiebreakers, possibles, fn step, possibles ->
      {{step, possibles}, Enum.reject(possibles, &(elem(&1, 1) == step))}
    end)
    |> elem(0)
  end

  @spec get_tiebreak_select(atom()) :: {String.t(), atom()}
  defp get_tiebreak_select(step), do: {Map.get(@tiebreak_copy, step), step}

  @spec get_form_label(atom()) :: String.t()
  defp get_form_label(name), do: Map.get(@form_labels, name, capitalize_each_word(name))

  @spec get_select_options(atom()) :: [{String.t(), any()}]
  defp get_select_options(:do_finals_reset), do: [{"No", false}, {"Yes", true}]

  defp get_select_options(:has_first_round_losers),
    do: [{"All in upper bracket", false}, {"Split between upper and lower brackets", true}]

  defp get_select_options(:do_randomize_pairing),
    do: [{"Score groups + random", true}, {"Score groups + opposite", false}]

  defp get_select_options(_name),
    do: [
      {"Best of 3", 3},
      {"Best of 5", 5},
      {"Best of 7", 7},
      {"Fixed Games", :enable_custom_input},
      {"Home & Away", 2},
      {"Single Game", 1}
    ]

  defp get_custom_input_label(:match_games), do: "Number of Fixed Games"
  defp get_custom_input_label(_), do: "Custom Input"
end
