defmodule StridentWeb.MyTournamentsLive.Index do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Tournaments

  @page_size 8
  @status_filters %{
    "All" => %{},
    "Live and Upcoming" => %{
      status: [:scheduled, :registrations_open, :registrations_closed, :in_progress],
      sort: %{sort_order: :asc}
    },
    "Past Tournaments" => %{status: [:under_review, :finished], sort: %{sort_order: :desc}},
    "Canceled" => %{
      status: [:cancelled],
      sort: %{sort_order: :desc}
    }
  }
  @user_relation_filters [
    {"Operating", :with_creator_or_management_personnel},
    {"Playing In", :with_participant},
    {"Following", :followed_by}
  ]

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    socket
    |> assign(
      filtered_status: "Live and Upcoming",
      filtered_user_relation_index: 0,
      current_user_id: current_user.id,
      number_loaded: @page_size,
      page_title: "My Tournaments"
    )
    |> apply_filters()
    |> then(&{:ok, &1, layout: {StridentWeb.LayoutView, :live}})
  end

  @impl true
  def handle_event("filter-user-relation", %{"filter-type" => filter_type}, socket) do
    socket
    |> assign(filtered_user_relation_index: String.to_integer(filter_type))
    |> apply_filters()
    |> then(&{:noreply, &1})
  end

  def handle_event(
        "filter-status",
        %{"filter_status_form" => %{"filter" => filter_by_status}},
        socket
      ) do
    socket
    |> assign(filtered_status: filter_by_status)
    |> apply_filters()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("load-more", _, %{assigns: %{number_loaded: number_loaded}} = socket) do
    socket
    |> assign(number_loaded: number_loaded + @page_size)
    |> apply_filters()
    |> then(&{:noreply, &1})
  end

  defp apply_filters(%{assigns: assigns} = socket) do
    {_, user_relation} = Enum.at(@user_relation_filters, assigns.filtered_user_relation_index)

    @status_filters
    |> Map.get(assigns.filtered_status, %{})
    |> Map.merge(%{
      user_relation => assigns.current_user_id,
      all_datetimes: true,
      limit: assigns.number_loaded,
      filter_by_scrims_or_tournaments: false,
      show_private: user_relation != :followed_by
    })
    |> Keyword.new()
    |> Tournaments.get_tournaments_with_filters()
    |> then(&assign(socket, :tournaments, &1))
  end

  defp user_relation_filters, do: Enum.map(@user_relation_filters, &elem(&1, 0))
  defp status_filters, do: Map.keys(@status_filters)
end
