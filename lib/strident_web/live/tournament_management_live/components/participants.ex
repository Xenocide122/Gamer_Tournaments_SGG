defmodule StridentWeb.TournamentManagement.Components.Participants do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.StringUtils
  alias Strident.Tournaments
  alias StridentWeb.TournamentManagement.Components.Participant
  alias Phoenix.LiveView.JS

  @status_filters [
    %{type: :confirmed, title: "Entry fee paid", selected: false},
    %{type: :contribution_to_entry_fee, title: "Raising Funds", selected: false},
    %{type: :chip_in_to_entry_fee, title: "Accepting Contributions", selected: false}
  ]

  @impl true
  def mount(socket) do
    socket
    |> assign(:current_page, 0)
    |> assign(:total_pages, 0)
    |> assign(:participants, [])
    |> assign(:search_term, "")
    |> assign(:status_filters, @status_filters)
    |> assign(:selected_filters, [])
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    %{tournament: tournament, can_manage_tournament: can_manage_tournament} = assigns
    show_header = Map.get(assigns, :show_header, true)

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:can_manage_tournament, can_manage_tournament)
    |> assign(:show_header, show_header)
    |> assign(:tournament, tournament)
    |> assign_ranks_frequency()
    |> assign_participants()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("next-page", _params, socket) do
    %{assigns: %{total_pages: total_pages, current_page: current_page}} = socket

    if total_pages > current_page do
      {:noreply, assign_participants(socket, current_page + 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("go-to-page", %{"page" => page_raw}, socket) do
    with %{assigns: %{total_pages: total_pages, current_page: current_page}} <- socket,
         {page, _} <- Integer.parse(page_raw),
         true <- page <= total_pages and page > 0,
         true <- page != current_page do
      {:noreply, assign_participants(socket, page)}
    else
      _ ->
        socket
        |> put_flash(:info, "Error. Please return to the previous Participants page.")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("previous-page", _params, socket) do
    %{assigns: %{current_page: current_page}} = socket

    if current_page > 1 do
      {:noreply, assign_participants(socket, current_page - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search", %{"search_term" => search_term} = _params, socket) do
    socket
    |> assign(:search_term, search_term)
    |> assign_participants()
    |> update(:selected_filters, fn selected_filters ->
      selected_filters
      |> Enum.reject(fn filter -> String.contains?(filter, "Search") end)
      |> then(&["Search - #{search_term}" | &1])
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("clear-search-term", _params, socket) do
    socket
    |> assign(:search_term, "")
    |> assign_participants()
    |> update(
      :selected_filters,
      &Enum.reject(&1, fn filter -> String.contains?(filter, "Search") end)
    )
    |> then(&{:noreply, &1})
  end

  # @impl true
  # def handle_event("filter", %{"filter" => status_filters_params}, socket) do
  #   %{assigns: %{status_filters: status_filters}} = socket
  #   raising_funds_old = Enum.find(status_filters, &(&1.type == :contribution_to_entry_fee))
  #   raising_funds_new = Map.get(status_filters_params, "contribution_to_entry_fee")

  #   status_filters_new =
  #     if raising_funds_old.selected == false and convert_boolean(raising_funds_new) do
  #       Enum.map(status_filters, fn
  #         %{type: :raising_funds} = stake_filter -> %{stake_filter | selected: true}
  #         stake_filter -> %{stake_filter | selected: false}
  #       end)
  #     else
  #       Enum.map(status_filters, fn
  #         %{type: :raising_funds} = stake_filter ->
  #           %{stake_filter | selected: false}

  #         stake_filter ->
  #           selected =
  #             status_filters_params
  #             |> Map.get(Atom.to_string(stake_filter.type))
  #             |> convert_boolean()

  #           %{stake_filter | selected: selected}
  #       end)
  #     end

  #   socket
  #   |> assign(:status_filters, sstatus_filters_new)
  #   |> assign_participants()
  #   |> update(:selected_filters, fn selected_filters ->
  #     Enum.reduce(
  #       status_filters_new,
  #       Enum.filter(selected_filters, &String.contains?(&1, "Search")),
  #       fn
  #         %{selected: true} = stake_filter, filters -> [stake_filter.title | filters]
  #         _, filters -> filters
  #       end
  #     )
  #   end)
  #   |> then(&{:noreply, &1})
  # end

  @impl true
  def handle_event("remove-filter", %{"filter" => remove_filter}, socket) do
    socket
    |> then(fn socket ->
      if String.contains?(remove_filter, "Search") do
        assign(socket, :search_term, "")
      else
        update(socket, :status_filters, fn status_filters ->
          Enum.map(status_filters, fn filter ->
            if filter.title == remove_filter do
              %{filter | selected: false}
            else
              filter
            end
          end)
        end)
      end
    end)
    |> assign_participants()
    |> update(:selected_filters, fn selected_filters ->
      Enum.reduce(selected_filters, [], &if(&1 == remove_filter, do: &2, else: [&1 | &2]))
    end)
    |> then(&{:noreply, &1})
  end

  def assign_participants(socket, page \\ 1) do
    %{
      assigns: %{
        tournament: tournament,
        search_term: search_term,
        status_filters: status_filters
      }
    } = socket

    status_filters =
      Enum.reduce(status_filters, [], &if(&1.selected, do: [&1.type | &2], else: &2))

    %{entries: participants, total_pages: total_pages, page_number: current_page} =
      Tournaments.get_tournament_participants_for_tournament(tournament.id,
        page: page,
        search_term: search_term,
        filter_by: status_filters
      )

    socket
    |> assign(:current_page, current_page)
    |> assign(:total_pages, total_pages)
    |> assign(:participants, participants)
  end

  def assign_ranks_frequency(socket) do
    %{assigns: %{tournament: tournament}} = socket

    ranks_frequency =
      Enum.reduce(tournament.participants, %{}, fn %{rank: rank}, acc ->
        Map.update(acc, rank, 1, &(&1 + 1))
      end)

    assign(socket, :ranks_frequency, ranks_frequency)
  end

  def sort_participants(participants) do
    if Enum.any?(participants, fn p -> p.rank end) do
      Enum.sort_by(participants, & &1.rank)
    else
      Enum.sort_by(participants, & &1.inserted_at, NaiveDateTime)
    end
  end

  def show_dropdown(to) do
    JS.show(
      to: to,
      transition:
        {"transition ease-out duration-120", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
    |> JS.set_attribute({"aria-expanded", "true"}, to: to)
  end

  def hide_dropdown(to) do
    JS.hide(
      to: to,
      transition:
        {"transition ease-in duration-120", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.remove_attribute("aria-expanded", to: to)
  end
end
