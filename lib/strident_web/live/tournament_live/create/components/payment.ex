defmodule StridentWeb.TournamentLive.Create.Payment do
  @moduledoc """
  The "Payment" page, where user invites parties/teams.
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{f: f, tournament_info: tournament_info} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:f, f)
    |> assign(:tournament_info, tournament_info)
    |> then(&{:ok, &1})
  end
end
