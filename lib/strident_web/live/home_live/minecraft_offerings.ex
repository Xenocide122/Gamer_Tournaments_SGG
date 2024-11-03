defmodule StridentWeb.HomeLive.MinecraftOfferings do
  @moduledoc false
  require Logger
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    category_labels = [
      educational_worlds: "Educational Worlds",
      stride_server: "Stride Server",
      mini_games: "Mini Games",
      build_challenge: "Build Challenge"
    ]

    socket
    |> assign(:category_labels, category_labels)
    |> then(&{:ok, &1})
  end
end
