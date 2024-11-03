defmodule StridentWeb.TeamWinningsLive.Show do
  @moduledoc false
  use StridentWeb, :live_view

  on_mount StridentWeb.TeamManagment.Setup

  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    {:ok, assign_socket(socket, slug, params)}
  end

  def assign_socket(socket, _slug, _params) do
    socket
    |> assign(:team_site, :winnings)
    |> assign_page_title()
  end

  defp assign_page_title(%{assigns: %{team: team}} = socket) do
    assign(socket, page_title: team.name)
  end
end
