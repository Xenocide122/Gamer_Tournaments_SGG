defmodule StridentWeb.AdminLive.Index do
  @moduledoc false
  use StridentWeb, :live_view

  alias StridentWeb.AdminLive.Components.Menus

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
