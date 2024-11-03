defmodule StridentWeb.Components.RecentTournamentResults do
  @moduledoc false

  use StridentWeb, :live_component
  alias Strident.Extension.NaiveDateTime

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    assigns = Map.put_new(assigns, :limit, 4)

    socket
    |> assign_merged_results(assigns)
    |> assign(assigns)
    |> then(&{:ok, &1})
  end

  defp assign_merged_results(socket, %{
         recent_results: recent_results,
         recent_placements: recent_placements
       }) do
    results = merge(recent_results.entries, recent_placements.entries)
    assign(socket, results: results)
  end

  defp assign_merged_results(socket, %{recent_results: recent_results}) do
    assign(socket, results: recent_results.entries)
  end

  defp assign_merged_results(socket, %{recent_placements: recent_placements}) do
    assign(socket, results: recent_placements.entries)
  end

  defp merge([r | rs], [p | ps]) do
    if NaiveDateTime.diff(r.tournament.starts_at, p.date) < 0 do
      [p | merge([r | rs], ps)]
    else
      [r | merge(rs, [p | ps])]
    end
  end

  defp merge([], [p | ps]) do
    [p | merge([], ps)]
  end

  defp merge([r | rs], []) do
    [r | merge(rs, [])]
  end

  defp merge([], []) do
    []
  end
end
