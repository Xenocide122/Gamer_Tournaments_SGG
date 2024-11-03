defmodule StridentWeb.Components.Roster do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{
          name_vertical_padding: name_vertical_padding,
          team_or_party_members: team_or_party_members,
          team_rosters: rosters,
          game: game
        },
        socket
      ) do
    roster_id =
      Enum.find_value(rosters, fn %{game: %{slug: slug}, id: id} -> if slug === game, do: id end)

    players =
      team_or_party_members
      |> Enum.filter(fn %{team_roster_members: rosters} ->
        !roster_id or Enum.any?(rosters, fn %{team_roster_id: id} -> id === roster_id end)
      end)

    socket
    |> assign(:players, players)
    |> assign(:name_vertical_padding, name_vertical_padding)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(
        %{
          name_vertical_padding: name_vertical_padding,
          team_or_party_members: team_or_party_members
        },
        socket
      ) do
    socket
    |> assign(:players, team_or_party_members)
    |> assign(:name_vertical_padding, name_vertical_padding)
    |> assign(rosters: nil)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{name_vertical_padding: name_vertical_padding, players: players}, socket) do
    socket
    |> assign(:players, players)
    |> assign(:name_vertical_padding, name_vertical_padding)
    |> assign(rosters: nil)
    |> then(&{:ok, &1})
  end
end
