defmodule StridentWeb.Components.RosterThin do
  @moduledoc false
  use StridentWeb, :live_component

  @defaults %{
    position: :vertical
  }

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{team_or_party_members: team_members, team_rosters: rosters, roster: roster_slug} =
          assigns,
        socket
      ) do
    roster =
      Enum.find_value(rosters, fn %{slug: slug} = roster ->
        if slug === roster_slug, do: roster
      end)

    players =
      if roster do
        roster.members
        |> Enum.map(fn %{team_member_id: team_member_id} = member ->
          Map.merge(Enum.find(team_members, fn %{id: id} -> id == team_member_id end), member)
        end)
      else
        team_members
      end

    socket
    |> assign(:players, players)
    |> assign(Map.merge(@defaults, assigns))
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{team_or_party_members: team_or_party_members} = assigns, socket) do
    socket
    |> assign(:players, team_or_party_members)
    |> assign(Map.merge(@defaults, assigns))
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{players: players} = assigns, socket) do
    socket
    |> assign(:players, players)
    |> assign(Map.merge(@defaults, assigns))
    |> then(&{:ok, &1})
  end
end
