defmodule StridentWeb.TeamLive.SideMenu do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{team: team, current_menu_item: current_menu_item}, socket) do
    socket
    |> assign(:team, team)
    |> assign(:current_menu_item, current_menu_item)
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <aside class="w-64" aria-label="Sidebar">
      <div class="overflow-y-auto py-4 px-3">
        <ul class="space-y-2">
          <%= menu_item(%{
            url: Routes.live_path(@socket, StridentWeb.TeamProfileLive.Show, @team.slug),
            svg: :user_circle,
            title: "Profile",
            selected: @current_menu_item == :profile
          }) %>
          <%= menu_item(%{
            url: Routes.live_path(@socket, StridentWeb.TeamWinningsLive.Show, @team.slug),
            svg: :coins,
            title: "Winnings & Payouts",
            selected: @current_menu_item == :winnings
          }) %>
          <%= menu_item(%{
            url: Routes.live_path(@socket, StridentWeb.TeamRostersLive.Show, @team.slug),
            svg: :group,
            title: "Rosters",
            selected: @current_menu_item == :rosters
          }) %>
          <%= menu_item(%{
            url: Routes.live_path(@socket, StridentWeb.TeamTournamentsLive.Show, @team.slug),
            svg: :trophy,
            title: "Tournaments",
            selected: @current_menu_item == :tournaments
          }) %>
          <%= menu_item(%{
            url: Routes.live_path(@socket, StridentWeb.TeamSettingsLive.Show, @team.slug),
            svg: :settings,
            title: "Settings",
            selected: @current_menu_item == :settings
          }) %>
        </ul>
      </div>
    </aside>
    """
  end

  def menu_item(assigns) do
    ~H"""
    <li>
      <.link navigate={@url} class={"flex items-center px-2 py-1 #{selected_item(@selected)}"}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
          <path
            d={StridentWeb.Common.SvgUtils.path(@svg)}
            transform={if(@svg == :settings, do: "translate(-3.406 -3)")}
          >
          </path>
        </svg>
        <span class="ml-3">
          <%= @title %>
        </span>
      </.link>
    </li>
    """
  end

  def selected_item(true), do: "text-primary rounded-lg bg-blackish"

  def selected_item(false), do: "text-grey-light rounded-lg hover:bg-blackish"
end
