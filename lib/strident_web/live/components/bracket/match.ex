defmodule StridentWeb.Components.Bracket.Match do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div draggable="true" class="p-4 bg-transparent rounded draggable"><%= @participant_name %></div>
    """
  end
end
