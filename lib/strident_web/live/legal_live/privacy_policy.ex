defmodule StridentWeb.LegalLive.PrivacyPolicy do
  @moduledoc false
  use StridentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Privacy Policy")
    {:ok, socket}
  end
end
