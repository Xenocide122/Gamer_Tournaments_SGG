defmodule StridentWeb.TournamentLive.Create.Landing do
  @moduledoc """
  The "create tournament" landing page, where user can select the stages combination.
  """
  use StridentWeb, :live_component
  alias StridentWeb.TournamentLive.Create.StagesStructure, as: StagesStructureComponent
  @impl true
  def mount(socket) do
    socket
    |> assign(:saved_forms, [])
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    %{saved_forms: saved_forms, timezone: timezone, locale: locale} = assigns

    socket
    |> assign(%{saved_forms: saved_forms, timezone: timezone, locale: locale})
    |> then(&{:ok, &1})
  end
end
