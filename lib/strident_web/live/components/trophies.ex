defmodule StridentWeb.Components.Trophies do
  @moduledoc """
  Trophies components.
  """

  use Phoenix.Component

  @type placement_trophy_assigns :: %{
          optional(:rank) => integer(),
          optional(:tied_ranks) => integer()
        }

  @trophy_colors {"trophy-gold", "trophy-silver", "trophy-bronze"}

  @spec placement_trophy(atom() | placement_trophy_assigns()) :: Phoenix.LiveView.Rendered.t()
  def placement_trophy(%{rank: rank, tied_ranks: 1} = assigns)
      when is_integer(rank) do
    if rank < 3 do
      assigns = Map.put(assigns, :color, elem(@trophy_colors, rank))

      ~H"""
      <div class="flex items-center space-x-1">
        <svg xmlns="http://www.w3.org/2000/svg" width="45" viewBox="-1 -1 26 24" class={@color}>
          <path d={StridentWeb.Common.SvgUtils.path(:trophy)}></path>
        </svg>
        <h3>
          <%= Strident.Prizes.format_prize_rank(@rank) %>
        </h3>
      </div>
      """
    else
      ~H"""
      <h3>
        <%= Strident.Prizes.format_prize_rank(@rank) %>
      </h3>
      """
    end
  end

  def placement_trophy(%{rank: rank} = assigns) when is_integer(rank) do
    ~H"""
    <h3>
      Top <%= 1 + @rank %>
    </h3>
    """
  end

  def placement_trophy(assigns) do
    ~H"""
    <h4 class="text-muted">
      Unranked
    </h4>
    """
  end
end
