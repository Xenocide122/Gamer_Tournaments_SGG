defmodule StridentWeb.LegalLive.FairplayPolicy do
  @moduledoc false
  use StridentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Fair Play Policy")
    {:ok, socket}
  end
end
