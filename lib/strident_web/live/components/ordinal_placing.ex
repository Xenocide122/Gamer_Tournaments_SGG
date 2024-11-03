defmodule StridentWeb.Components.OrdinalPlacing do
  @moduledoc """
  Trophies components.
  """

  use Phoenix.Component

  @spec ordinal_placing(%{:rank => nil | non_neg_integer()}) :: Phoenix.LiveView.Rendered.t()
  def ordinal_placing(%{rank: nil} = assigns) do
    ~H"""

    """
  end

  def ordinal_placing(%{rank: rank}) when is_integer(rank) do
    ordinal_placing_string = Strident.Prizes.format_prize_rank(rank)
    regex = ~r{[0-9]+}
    opts = [include_captures: true, trim: true]
    [number_string, ordinal_part_string] = Regex.split(regex, ordinal_placing_string, opts)
    assigns = %{number_string: number_string, ordinal_part_string: ordinal_part_string}

    ~H"""
    <h2 class="flex items-start font-display text-primary text-center">
      <%= @number_string %>
      <span class="text-sm font-sans">
        <%= @ordinal_part_string %>
      </span>
    </h2>
    """
  end
end
