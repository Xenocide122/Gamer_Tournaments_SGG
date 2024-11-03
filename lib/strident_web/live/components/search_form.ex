defmodule StridentWeb.Live.Components.SearchForm do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{results: results, search_term: search_term} = assigns, socket) do
    socket
    |> assign(:placeholder, Map.get(assigns, :placeholder))
    |> assign(:search_term, search_term)
    |> assign(:search_results, results)
    |> assign(:current_focus, -1)
    |> assign(:target, Map.get(assigns, :target))
    |> assign(:phx_debounce, Map.get(assigns, :phx_debounce) || 100)
    |> assign(:render_result_fn, Map.get(assigns, :render_result_fn) || (&stringify_result/1))
    |> then(&{:ok, &1})
  end

  @doc """
  Implementation of keys ArrowUp, ArrowDown, still on implementation list is ENTER
  where we need to send it to the target.
  """
  @impl true
  def handle_event(
        "set-focus",
        %{"key" => "ArrowUp"},
        %{assigns: %{current_focus: current_focus}} = socket
      ) do
    current_focus = Enum.max([current_focus - 1, 0])
    {:noreply, assign(socket, current_focus: current_focus)}
  end

  @impl true
  def handle_event(
        "set-focus",
        %{"key" => "ArrowDown"},
        %{assigns: %{current_focus: current_focus, search_results: search_results}} = socket
      ) do
    current_focus = Enum.min([current_focus + 1, length(search_results) - 1])

    {:noreply, assign(socket, current_focus: current_focus)}
  end

  # @doc """
  # We should implement ENTER here
  # """
  # @impl true
  # def handle_event(
  #       "set-focus",
  #       %{"key" => "Enter"},
  #       %{assigns: %{current_focus: current_focus, search_results: search_results}} = socket
  #     ) do
  #   case Enum.at(search_results, current_focus) do
  #     %{} = element -> {:noreply, push_event(socket, "pick", %{"id" => element.id})}
  #     _ -> {:noreply, socket}
  #   end
  # end

  @impl true
  def handle_event("set-focus", _params, socket), do: {:noreply, socket}

  defp stringify_result(%{search_result: %{name: name}}), do: name
  defp stringify_result(%{search_result: %{display_name: name}}), do: name
end
