defmodule StridentWeb.TournamentLive.Create.PageProgress do
  @moduledoc """
  The "page progress" side element, showing current page and previous page statuses.
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    socket
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{changeset: %{changes: changes}, current_page: current_page, pages: pages}, socket) do
    active_pages = [current_page]

    {pages, _} =
      pages
      |> Enum.reject(&(&1 in [:landing, :tournament_type, :custom_tournament]))
      |> Enum.map_reduce({true, false}, fn page, {prev_page_valid, reached_active_page} ->
        reached_active_page = reached_active_page or page in active_pages
        is_previous_page = not reached_active_page

        is_valid =
          case Map.get(changes, page) do
            %{valid?: valid?} -> valid?
            _ -> true
          end

        {{page, is_previous_page, prev_page_valid},
         {is_valid and prev_page_valid, reached_active_page}}
      end)

    socket
    |> assign(:active_pages, active_pages)
    |> assign(:pages, pages)
    |> then(&{:ok, &1})
  end
end
