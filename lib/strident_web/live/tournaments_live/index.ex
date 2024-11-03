defmodule StridentWeb.TournamentsLive.Index do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Extension.DateTime
  alias Strident.Extension.NaiveDateTime
  alias Strident.Games
  alias Strident.StringUtils
  alias Strident.Tournaments
  alias StridentWeb.SegmentAnalyticsHelpers

  on_mount({StridentWeb.InitAssigns, :default})

  @status_filters %{
    "live-tournament" => %{status: [:in_progress]},
    "accepting-contributions" => %{status: [:registrations_open, :registrations_closed]},
    "open-registration" => %{status: [:scheduled, :registrations_open], type: [:casting_call]}
  }
  @page_size 16

  @default_timezone Application.compile_env(:strident, :default_timezone)

  @impl true
  def mount(_params, _session, socket) do
    genres = Games.list_genres()

    socket
    |> assign(
      :featured_tournaments,
      Tournaments.list_featured_tournaments_with_game_summaries()
    )
    |> assign(:games, Games.list_games() |> Enum.sort_by(& &1.title, :asc))
    |> assign(:num_genres_displayed, 5)
    |> assign(:genres, genres)
    |> assign(:page_title, "Tournaments")
    |> then(&{:ok, &1, layout: {StridentWeb.LayoutView, :live}})
  end

  @impl true
  def handle_params(params, _uri, socket) do
    games =
      Map.get(params, "games", "")
      |> String.split(",", trim: true)

    genres =
      Map.get(params, "genres", "")
      |> String.split(",", trim: true)

    status =
      Map.get(params, "status", "")
      |> String.split(",", trim: true)

    dates =
      Map.get(params, "dates", "")
      |> String.split(",", trim: true)
      |> Enum.map(fn date_string ->
        date? =
          date_string
          |> String.trim()
          |> Date.from_iso8601()

        case date? do
          {:ok, date} -> date
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    search = Map.get(params, "search", nil)

    number_loaded =
      case Integer.parse(Map.get(params, "number", "")) do
        {int, _} -> int
        _ -> @page_size
      end

    show_scrims =
      case Map.get(params, "show_scrims", "") do
        "true" -> true
        _ -> false
      end

    displayed_games =
      if genres == [] do
        socket.assigns.games
      else
        Games.list_games_with_genre_slugs(genres)
      end

    games = Enum.filter(games, &Enum.any?(displayed_games, fn game -> game.slug == &1 end))

    socket
    |> assign(:filtered_games, games)
    |> assign(:filtered_genres, genres)
    |> assign(:filtered_status, status)
    |> assign(:filtered_dates, dates)
    |> assign(:filtered_search, search)
    |> assign(:number_loaded, number_loaded)
    |> assign(:show_scrims, show_scrims)
    |> maybe_track_segment_tournaments_filtered(
      games,
      status,
      dates,
      search,
      show_scrims
    )
    |> assign(:displayed_games, displayed_games)
    |> apply_filters()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("show-scrims", _params, socket) do
    socket
    |> update(:show_scrims, &(not &1))
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("filter-games", %{"filtered_games" => params}, socket) do
    games = keys_with_string_value_true(params)

    socket
    |> assign(filtered_games: games)
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("unfilter-games", _, socket) do
    socket
    |> assign(filtered_games: [])
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("filter-genre", %{"genre" => genre}, socket) do
    socket
    |> assign(filtered_genres: [genre])
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("unfilter-genres", _, socket) do
    socket
    |> assign(filtered_genres: [])
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  def handle_event("more-genres", _, socket) do
    socket
    |> update(:num_genres_displayed, fn num_genres_displayed ->
      min(num_genres_displayed + 10, 100)
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("filter-status", %{"filtered_status" => params}, socket) do
    status = keys_with_string_value_true(params)

    socket
    |> assign(filtered_status: status)
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("unfilter-status", _, socket) do
    socket
    |> assign(filtered_status: [])
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("unfilter-scrims", _params, socket) do
    socket
    |> assign(:show_scrims, false)
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("filter-dates", %{"filtered_dates" => %{"date" => dates_string}}, socket) do
    timezone = Map.get(socket.assigns, :timezone) || @default_timezone

    dates =
      dates_string
      |> String.split("to")
      |> Enum.map(fn date_string ->
        date? =
          date_string
          |> String.trim()
          |> NaiveDateTime.from_iso8601()

        case date? do
          {:ok, date} ->
            date
            |> DateTime.from_naive!("Etc/UTC")
            |> DateTime.shift_zone!(timezone)
            |> DateTime.to_date()

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    socket
    |> assign(filtered_dates: dates)
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("unfilter-date", _, socket) do
    socket
    |> assign(filtered_dates: [])
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("filter-search", %{"search_term" => term}, socket) do
    socket
    |> assign(filtered_search: String.trim(term))
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("unfilter-search", _, socket) do
    socket
    |> assign(filtered_search: "")
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("load-more", _, %{assigns: %{number_loaded: number_loaded}} = socket) do
    socket
    |> assign(number_loaded: number_loaded + 8)
    |> apply_patch()
    |> then(&{:noreply, &1})
  end

  def maybe_track_segment_tournaments_filtered(
        socket,
        games,
        status,
        dates,
        search,
        show_scrims
      ) do
    if Enum.any?(games) or Enum.any?(status) or Enum.any?(dates) or not is_nil(search) or
         show_scrims do
      socket
      |> SegmentAnalyticsHelpers.track_segment_event("Tournaments Filtered", %{
        filtered_games: games,
        filtered_status: status,
        filtered_dates: dates,
        filtered_search: search,
        filtered_scrims: show_scrims
      })
    else
      socket
    end
  end

  defp apply_filters(%{assigns: assigns} = socket) do
    datetimes =
      unlocalize_dates(assigns.filtered_dates, Map.get(assigns, :timezone) || @default_timezone)

    filters =
      generate_status_filters(assigns.filtered_status)
      |> Keyword.merge(
        times: datetimes,
        games: assigns.filtered_games,
        game_genres: assigns.filtered_genres,
        search_term: assigns.filtered_search,
        limit: assigns.number_loaded,
        sort: :closest,
        filter_by_scrims_or_tournaments: if(assigns.show_scrims, do: :scrims, else: :tournaments)
      )

    filtered_tournaments =
      Tournaments.get_tournaments_with_filters(filters, [:participants, :game])

    assign(socket, filtered_tournaments: filtered_tournaments)
  end

  defp apply_patch(%{assigns: assigns} = socket) do
    dates = Enum.map_join(assigns.filtered_dates, ",", &Date.to_iso8601/1)

    params =
      %{
        games: Enum.join(assigns.filtered_games, ","),
        genres: Enum.join(assigns.filtered_genres, ","),
        status: Enum.join(assigns.filtered_status, ","),
        dates: dates,
        search: assigns.filtered_search,
        number: if(assigns.number_loaded != @page_size, do: "#{assigns.number_loaded}"),
        show_scrims: to_string(assigns.show_scrims)
      }
      |> Map.reject(&StringUtils.is_empty?(elem(&1, 1)))

    push_patch(socket, to: Routes.tournament_index_path(socket, :index, params))
  end

  defp generate_status_filters(status) do
    status
    |> Enum.map(&Map.get(@status_filters, &1, %{}))
    |> Enum.reduce(
      %{},
      &Map.merge(&1, &2, fn _k, v1, v2 ->
        Enum.concat(v1, v2)
        |> Enum.uniq()
      end)
    )
    |> Map.put_new(:status, [
      :scheduled,
      :registrations_open,
      :registrations_closed,
      :in_progress,
      :under_review,
      :finished
    ])
    |> Keyword.new()
  end

  defp keys_with_string_value_true(map) do
    map
    |> Map.filter(&(elem(&1, 1) == "true"))
    |> Map.keys()
  end

  defp game_titles(selected_games, games) do
    Enum.map(
      selected_games,
      &Enum.find_value(games, String.capitalize(String.replace(&1, "-", " ")), fn game ->
        if game.slug == &1, do: game.title
      end)
    )
  end

  defp unlocalize_dates([], _), do: []
  defp unlocalize_dates([date], timezone), do: unlocalize_dates([date, date], timezone)

  defp unlocalize_dates([start_date, end_date], timezone) do
    start_datetime =
      start_date
      |> DateTime.new!(Time.new!(0, 0, 0), timezone)
      |> DateTime.shift_zone!("Etc/UTC")
      |> DateTime.to_naive()

    end_datetime =
      end_date
      |> DateTime.new!(Time.new!(23, 59, 59), timezone)
      |> DateTime.shift_zone!("Etc/UTC")
      |> DateTime.to_naive()

    [start_datetime, end_datetime]
  end

  defp status_filters, do: Map.keys(@status_filters)
end
