defmodule StridentWeb.TournamentLive.Create.StagesStructure do
  @moduledoc false
  use StridentWeb, :live_component
  alias Phoenix.HTML.Format, as: HtmlFormat

  @impl true
  def update(_assigns, socket) do
    socket
    |> assign(:stages_structures, stages_structures())
    |> then(&{:ok, &1})
  end

  defp stages_structures do
    [
      %{
        id: :single_elimination,
        title: "Single Elimination",
        description: "The classic bracket experience.\nWinners move on, losers go home.",
        img_src: "/images/single_elim.svg"
      },
      %{
        id: :double_elimination,
        title: "Double Elimination",
        description: "Two losses and you're out.\nLosers get one chance at redemption.",
        img_src: "/images/double_elim.svg"
      },
      %{
        id: :round_robin,
        title: "Round Robin",
        description:
          "Everyone gets a shot at everyone else.\nTop of the heap takes home the prize.",
        img_src: "/images/round_robin_elim.svg"
      },
      %{
        id: :swiss,
        title: "Swiss",
        description: "Play against others with the same record.\nThe cream rises to the top.",
        img_src: "/images/swiss_elim.svg"
      },
      %{
        id: :battle_royale,
        title: "Battle Royale",
        description: "Whether it's one round or many, there will only be one left standing.",
        img_src: "/images/battle_royale_symbol.svg"
      },
      %{
        id: :two_stage,
        title: "Two Stage",
        description: "Choose from any two of these stage\ntypes. You're the boss!!",
        img_src: "/images/two_stage_elim.svg"
      }
    ]
    |> Enum.map(fn stages_structure ->
      Map.update!(stages_structure, :description, &HtmlFormat.text_to_html/1)
    end)
  end
end
