defmodule StridentWeb.TournamentSettingsLive.Components.BracketsStructure do
  @moduledoc """
  Allow the TO to change the stage types
  """
  use StridentWeb, :live_component
  alias Ecto.Changeset
  alias StridentWeb.TournamentLive.Create.BracketsStructure, as: BracketsStructureComponent
  alias StridentWeb.TournamentLive.Create.StagesStructure, as: StagesStructureComponent

  @assigns_keys [:id, :brackets_structure_changeset, :stages_structure]

  @impl true
  def update(assigns, socket) do
    %{brackets_structure_changeset: brackets_structure_changeset} = assigns

    show_submit_button =
      brackets_structure_changeset.valid? and Enum.any?(brackets_structure_changeset.changes)

    show_two_stage =
      brackets_structure_changeset
      |> Changeset.get_field(:types)
      |> Enum.count()
      |> Kernel.>(1)

    socket
    |> assign(Map.take(assigns, @assigns_keys))
    |> assign(:show_two_stage, show_two_stage)
    |> assign(:show_submit_button, show_submit_button)
    |> then(&{:ok, &1})
  end
end
