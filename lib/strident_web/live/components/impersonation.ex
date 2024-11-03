defmodule StridentWeb.Components.Impersonation do
  @moduledoc """
  This component is used only for when the staff member will login as different user and
  should not be used anywhere else in the codebase.
  """
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.Accounts.User

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{impersonating_staff_id: impersonating_staff_id} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:impersonating_staff_id, impersonating_staff_id)
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg bg-secondary rounded p-10">
      <div class="flex items-center">
        <div class="flex flex-col">
          <div class="mb-4 text-xl">
            You are impersonating user:
            <p class="text-primary">
              <%= @current_user.display_name %>
            </p>
          </div>

          <div class="btn" phx-click="go-back" phx-target={@myself}>
            Go back to your profile
          </div>
        </div>

        <img class="mx-auto max-w-lg" src={safe_static_url("/images/impersonate.png")} />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "go-back",
        _params,
        %{assigns: %{impersonating_staff_id: impersonating_staff_id}} = socket
      ) do
    case Accounts.get_user_with_preloads_by(id: impersonating_staff_id) do
      %User{is_staff: true} ->
        socket
        |> push_navigate(to: Routes.impersonate_user_path(socket, :unimpersonate))
        |> then(&{:noreply, &1})

      _ ->
        # This should logout user, since he is using this feature that he shouldn't have
        socket
        |> push_navigate(to: Routes.user_session_path(socket, :delete))
        |> then(&{:noreply, &1})
    end
  end
end
