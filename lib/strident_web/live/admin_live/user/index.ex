defmodule StridentWeb.AdminLive.User.Index do
  @moduledoc false
  use StridentWeb, :live_view
  import StridentWeb.AdminLive.Components.Menus
  import StridentWeb.AdminLive.User.Components
  require Logger
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-16 mt-16 text-center md:text-left">
      <div id="admin-users" class="container space-y-4">
        <div class="lg:px-3">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-6xl leading-none tracking-normal font-display">Users</h3>
            </div>
            <div></div>
          </div>

          <div class="pb-5 mb-4 border-b border-gray-200 sm:pb-0">
            <div class="mt-3 sm:mt-4">
              <.tabs selected={:users} />
            </div>
          </div>

          <div :if={@is_connected} class="mb-4">
            <.search_users_filter />
          </div>

          <div
            :if={Enum.any?(@users)}
            id="refetch-data-button"
            class="mb-4 text-primary clickable"
            phx-click={
              JS.push("refetch-data")
              |> JS.show(to: "#fetching-message", transition: "fade-in", time: 2000)
              |> JS.hide(to: "#refetch-data-button")
            }
            phx-throttle="2000"
            js-trigger-data-fetched
            js-action-data-fetched={
              JS.hide(to: "#fetching-message")
              |> JS.show(to: "#refetch-data-button", transition: "fade-in", time: 200)
            }
          >
            Re-fetch data
          </div>

          <div id="fetching-message" class="hidden">
            Fetching...
          </div>

          <.table :if={Enum.any?(@users)} rows={@users}>
            <:col :let={user} label="Display Name">
              <%= user.display_name %>
            </:col>

            <:col :let={user} label="Email">
              <%= user.email %>
            </:col>

            <:col :let={user} label="Impersonate">
              <div
                :if={@current_user && @current_user.is_staff && !user.is_staff}
                class="cursor-pointer text-secondary"
                phx-value-user={user.id}
                phx-click="impersonate"
              >
                Impersonate This User
              </div>
            </:col>
          </.table>

          <.pagination total_pages={@total_pages} current_page={@page} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    is_connected = connected?(socket)

    socket
    |> assign(:amount, Money.zero(:XGR))
    |> assign(:transaction_type, "deposit")
    |> assign(:search_term, nil)
    |> assign(:page, 1)
    |> assign(:limit, 50)
    |> assign_users()
    |> assign(:is_connected, is_connected)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("set-amount", %{"keypad" => params}, socket) do
    socket
    |> update(:amount, fn amount ->
      case params["input"]["amount"] do
        "" -> amount
        amount -> Money.new(:XGR, amount)
      end
    end)
    |> assign(:transaction_type, params["transaction_type"])
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("search", %{"search_users" => %{"search_term" => search_term}}, socket)
      when is_binary(search_term) and byte_size(search_term) > 2 do
    socket
    |> assign(:search_term, search_term)
    |> assign(:page, 1)
    |> assign_users()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("search", _params, socket) do
    socket
    |> assign(:search_term, nil)
    |> assign(:page, 1)
    |> assign_users()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("refetch-data", _params, socket) do
    socket
    |> assign_users()
    |> push_event("data-fetched", %{})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("close-search", _params, socket) do
    socket
    |> assign(:search_term, nil)
    |> assign(:page, 1)
    |> assign_users()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("next-page", _params, socket) do
    %{page: page, total_pages: total_pages} = socket.assigns

    if page <= total_pages do
      socket
      |> update(:page, &(&1 + 1))
      |> assign_users()
    else
      socket
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("previous-page", _params, socket) do
    %{page: page} = socket.assigns

    if page > 0 do
      socket
      |> update(:page, &(&1 - 1))
      |> assign_users()
    else
      socket
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("go-to-page", params, socket) do
    %{total_pages: total_pages} = socket.assigns
    %{"page" => page_raw} = params
    {page, _rem} = Integer.parse(page_raw)

    if page > 0 and page <= total_pages do
      socket
      |> assign(:page, page)
      |> assign_users()
    else
      socket
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("impersonate", params, socket) do
    %{"user" => user_id} = params
    %{current_user: current_user} = socket.assigns

    case Accounts.get_user_with_preloads_by(id: current_user.id) do
      %User{is_staff: true} ->
        user = Accounts.get_user_with_preloads_by(id: user_id)

        push_navigate(socket,
          to: Routes.impersonate_user_path(socket, :impersonate, user_id: user.id)
        )

      _ ->
        put_flash(socket, :error, "You don't have permission for this action")
    end
    |> then(&{:noreply, &1})
  end

  defp assign_users(socket) do
    %{search_term: search_term, limit: limit, page: page} = socket.assigns

    if is_nil(search_term) || String.length(search_term) < 3 do
      socket
      |> assign(:page, 1)
      |> assign(:total_pages, 1)
      |> assign(:users, [])
    else
      %{entries: users, page_number: page_number, total_pages: total_pages} =
        Accounts.list_users_with_emails_and_preloads(search_term, [page: page, limit: limit], [])

      socket
      |> assign(:page, page_number)
      |> assign(:total_pages, total_pages)
      |> assign(:users, users)
    end
  end
end
