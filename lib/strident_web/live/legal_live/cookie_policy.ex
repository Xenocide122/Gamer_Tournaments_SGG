defmodule StridentWeb.LegalLive.CookiePolicy do
  @moduledoc false
  use StridentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Cookie Policy")
    {:ok, socket}
  end
end
