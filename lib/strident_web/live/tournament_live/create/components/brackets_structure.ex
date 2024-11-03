defmodule StridentWeb.TournamentLive.Create.BracketsStructure do
  @moduledoc """
  The "create tournament" form page, where user provides details.
  """
  use StridentWeb, :live_component
  alias Strident.DraftForms.CreateTournament.BracketsStructure
  alias Strident.Stages.StageSetting

  defp types do
    BracketsStructure
    |> Ecto.Enum.values(:types)
    |> Enum.map(&{&1, humanize(&1)})
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{f: f, stages: stages, stages_structure: stages_structure}, socket) do
    socket
    |> assign(:f, f)
    |> assign(:stages_structure, stages_structure)
    |> assign(:stages, stages)
    |> then(&{:ok, &1})
  end

  @type stage_types :: [{StageSetting.stage_type(), non_neg_integer()}]
  @spec allowed_stage_types(stage_types(), non_neg_integer()) :: Keyword.t()
  defp allowed_stage_types(_stage_types, 0) do
    Keyword.take(types(), [:round_robin, :swiss, :battle_royale])
  end

  defp allowed_stage_types(_stage_types, 1) do
    Keyword.take(types(), [:single_elimination, :double_elimination, :battle_royale])
  end

  defp description(:round_robin, _stage_index),
    do:
      "Participants are split into groups. Everyone plays each other once. You choose how many move on to Stage 2."

  defp description(:swiss, _stage_index),
    do:
      "Each round, participants play against opponents with equal records. You choose how many rounds and how many move on."

  defp description(:single_elimination, _stage_index),
    do:
      "Participants are seeded based on their Stage 1 results. Winners keep playing, losers go home."

  defp description(:double_elimination, _stage_index),
    do:
      "Participants are seeded based on their Stage 1 results. Winners advance, losers get a second shot. Lose twice, though, and you're out."

  defp description(:battle_royale, 0),
    do:
      "One table to track all the stats for Battle Royale games. Create the stats you need, as many rounds as you need, and mark the winners."

  defp description(:battle_royale, 1),
    do:
      "Any number of winners from the first round are dropped into a single group. One table to track all the stats for Battle Royale games. Create the stats you need, as many rounds as you need, and mark the winners."
end
