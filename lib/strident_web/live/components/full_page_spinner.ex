defmodule StridentWeb.Components.FullPageSpinner do
  @moduledoc """
  A full-page spinner with highest z-index, to block all
  interaction.

  The following assigns can be passed:
  - `message` - the message to display
  - `svg_size` - an integer representing the size of the spinner
  """

  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    message = assigns[:message] || "Please wait..."
    svg_size = assigns[:svg_size] || 180
    radius = div(svg_size, 2)
    dash_array = div(svg_size * 3, 4)

    socket
    |> assign(:message, message)
    |> assign(:svg_size, svg_size)
    |> assign(:radius, radius)
    |> assign(:dash_array, dash_array)
    |> then(&{:ok, &1})
  end
end
