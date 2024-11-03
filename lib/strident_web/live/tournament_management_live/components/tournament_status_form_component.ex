defmodule StridentWeb.TournamentManagement.Components.TournamentStatusFormComponent do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Tournaments.Tournament

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{status: status} = assigns, socket) do
    statuses =
      Tournament
      |> Ecto.Enum.values(:status)
      |> Enum.reject(&(&1 == :cancelled))

    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      status: status,
      statuses: statuses
    })
    |> then(&{:ok, &1})
  end
end
