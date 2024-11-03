defmodule StridentWeb.Common.ProgressBar do
  @moduledoc """
  Progress bar component

  Uses the `progress` prop to fill the bar.

  `progress` can be a float, integer or Decimal.
  """
  use StridentWeb, :live_component
  alias Strident.DecimalUtils

  def update(%{progress: progress}, socket) do
    {:ok, assign(socket, :percent, DecimalUtils.rounded_percent(progress))}
  end

  def update(_assigns, socket) do
    {:ok, assign(socket, :percent, 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="progress-bar">
      <div class="progress-bar__fill" style={"transform: translateX(-#{100 - @percent}%)"}></div>
    </div>
    """
  end
end
