defmodule StridentWeb.AdminLive.Features.Index do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Features
  alias Strident.Features.Feature
  alias StridentWeb.AdminLive.Components.Menus

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:features, Features.list_features())
    |> assign(:tags, Ecto.Enum.values(Feature, :tags))
    |> then(&{:ok, &1})
  end
end
