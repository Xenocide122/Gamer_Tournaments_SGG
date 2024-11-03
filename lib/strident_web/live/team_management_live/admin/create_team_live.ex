defmodule StridentWeb.TeamManagementLive.CreateTeamLive do
  @moduledoc false
  use StridentWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Create team")}
  end
end
