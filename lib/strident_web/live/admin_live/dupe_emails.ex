defmodule StridentWeb.AdminLive.DupeEmails do
  @moduledoc """
  See and merge users with the same email (something the app does not suffer well)
  """
  use StridentWeb, :live_view
  import StridentWeb.AdminLive.Components.Menus
  alias Strident.UserMerge

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-16 mt-16 text-center md:text-left">
      <div id="admin-dupe-emails" class="container space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-6xl leading-none tracking-normal font-display">Users</h3>
          </div>
          <div></div>
        </div>

        <div class="pb-5 mb-4 border-b border-gray-200 sm:pb-0">
          <div class="mt-3 sm:mt-4">
            <.tabs selected={:dupe_emails} />
          </div>
        </div>

        <button
          phx-click="list-dupe-email-users"
          class="btn btn-secondary hover:bg-red-500 hover:text-2xl hover:text-black"
        >
          <p>
            List Dupe emails (This is a very resource-intensive function, don't click it on a whim)
          </p>
        </button>

        <div :if={Enum.any?(@dupe_email_users)} class="gap-y-4 divider-x-2">
          <div :for={{email, users} <- @dupe_email_users}>
            <b><%= email %></b>

            <.table :if={Enum.any?(users)} rows={users}>
              <:col :let={user} label="Slug">
                <%= user.slug %>
              </:col>

              <:col :let={user} label="Display Name">
                <%= user.display_name %>
              </:col>

              <:col :let={user} label="Inserted At">
                <%= user.inserted_at %>
              </:col>

              <:col :let={user} label="Password?" class="text-primary">
                <%= if !!user.password_credential, do: "password" %>
              </:col>

              <:col :let={user} label="Unconfirmed?" class="text-secondary uppercase">
                <%= if !!user.password_credential && !user.password_credential.confirmed_at,
                  do: "UNCONFIRMED" %>
              </:col>

              <:col :let={user} label="discord" class="text-primary">
                <%= if !!user.discord_credential, do: "discord" %>
              </:col>

              <:col :let={user} label="twitch" class="text-primary">
                <%= if !!user.twitch_credential, do: "twitch" %>
              </:col>

              <:col :let={user} label="apple" class="text-primary">
                <%= if !!user.apple_credential, do: "apple" %>
              </:col>
            </.table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:dupe_email_users, [])
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("list-dupe-email-users", _params, socket) do
    socket
    |> assign(:dupe_email_users, list_dupe_email_users())
    |> then(&{:noreply, &1})
  end

  defp list_dupe_email_users do
    UserMerge.list_dupe_email_users()
  end
end
