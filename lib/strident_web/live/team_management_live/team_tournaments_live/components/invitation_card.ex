defmodule StridentWeb.TeamTournamentsLive.Components.InvitationCard do
  @moduledoc """
  Tournament card
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{open_invitation: true}, socket) do
    {:ok, assign(socket, :open_invitation, true)}
  end

  @impl true
  def update(%{close_invitation: true}, socket) do
    {:ok, assign(socket, :open_invitation, false)}
  end

  @impl true
  def update(
        %{
          tournament: tournament,
          tournament_invitation: tournament_invitation,
          team: team,
          id: id
        } = assigns,
        socket
      ) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:invitation, tournament_invitation)
    |> assign(:tournament, tournament)
    |> assign(:team, team)
    |> assign(:open_invitation, false)
    |> assign(:id, id)
    |> then(&{:ok, &1})
  end
end
