defmodule StridentWeb.TeamProfileLive.TournamentsComponent do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :selected_filter, "upcoming")}
  end

  @impl true
  def update(%{stakes: stakes} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:stakes, stakes)
    |> assign(
      :show_stakes,
      Enum.filter(stakes, fn %{tournament_participant: %{tournament: %{status: status}}} ->
        status in [:scheduled, :registrations_open, :in_progress]
      end)
    )
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "filter",
        %{"tournaments" => %{"filter" => "upcoming"}},
        %{assigns: %{stakes: stakes}} = socket
      ) do
    filtered_stakes =
      Enum.filter(stakes, fn %{tournament_participant: %{tournament: %{status: status}}} ->
        status in [:scheduled, :registrations_open, :in_progress]
      end)

    {:noreply, assign(socket, show_stakes: filtered_stakes, selected_filter: "upcoming")}
  end

  @impl true
  def handle_event(
        "filter",
        %{"tournaments" => %{"filter" => "past"}},
        %{assigns: %{stakes: stakes}} = socket
      ) do
    filtered_stakes =
      Enum.filter(stakes, fn %{tournament_participant: %{tournament: %{status: status}}} ->
        status == :under_review or status == :finished
      end)

    {:noreply, assign(socket, show_stakes: filtered_stakes, selected_filter: "past")}
  end
end
