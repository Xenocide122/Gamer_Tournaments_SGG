defmodule StridentWeb.Components.ClickableTooltip do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{text: text} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:text, text)
    |> assign(:class, assigns[:class] || [])
    |> assign(:modal_class, assigns[:modal_class] || [])
    |> then(&{:ok, &1})
  end
end
