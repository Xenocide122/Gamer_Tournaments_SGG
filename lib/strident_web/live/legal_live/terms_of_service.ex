defmodule StridentWeb.LegalLive.TermsOfService do
  @moduledoc false
  use StridentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Terms of Service")
    {:ok, socket}
  end
end
