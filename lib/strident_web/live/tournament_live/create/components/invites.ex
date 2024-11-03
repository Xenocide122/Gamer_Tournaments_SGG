defmodule StridentWeb.TournamentLive.Create.Invites do
  @moduledoc """
  The "invites" page, where user invites parties/teams.
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{f: f, stages_structure: stages_structure, invites: invites}, socket) do
    socket
    |> assign(:f, f)
    |> assign(:stages_structure, stages_structure)
    |> assign(:invites, invites)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("toggle-input-method", _unsigned_params, socket) do
    socket
    |> update(:invites, fn invites ->
      input_method = if Map.get(invites, :input_method) == :bulk, do: :single, else: :bulk
      Map.put(invites, :input_method, input_method)
    end)
    |> then(&{:noreply, &1})
  end
end
