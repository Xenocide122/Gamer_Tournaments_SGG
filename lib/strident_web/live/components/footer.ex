defmodule StridentWeb.Components.Footer do
  @moduledoc """
  Footer component
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
