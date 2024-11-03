defmodule StridentWeb.PatchNotesLive do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Changelogs

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_page_title()
      |> assign_page_description()
      |> assign_changelogs()

    {:ok, socket}
  end

  defp assign_page_title(socket) do
    socket
    |> assign(:page_title, "Patch Notes")
  end

  defp assign_page_description(socket) do
    socket
    |> assign(:page_description, "Follow along with updates and improvements made to Stride")
  end

  defp assign_changelogs(socket) do
    changelogs = Changelogs.list_changelogs()

    socket
    |> assign(:changelogs, changelogs)
  end
end
