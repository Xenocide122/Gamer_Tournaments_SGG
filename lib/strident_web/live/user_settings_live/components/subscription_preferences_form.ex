defmodule StridentWeb.UserSettingsLive.SubscriptionPreferencesForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.Accounts.User

  @impl true
  def mount(socket) do
    socket
    |> assign(%{updated: false})
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign_changeset()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "submit-subscription",
        %{"user" => %{"subscribe_to_emails" => "true"}},
        %{assigns: %{current_user: %{subscribe_to_emails: false} = user}} = socket
      ) do
    case Accounts.resubscribe_to_emails(user) do
      {:ok, _user} ->
        update_subscribe_to_emails_in_parent(true)
        {:noreply, assign(socket, :updated, true)}

      _ ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Could not subscribe to emails. Please reload the page and try again."
         )}
    end
  end

  @impl true
  def handle_event(
        "submit-subscription",
        %{"user" => %{"subscribe_to_emails" => "false"}},
        %{assigns: %{current_user: %{subscribe_to_emails: true} = user}} = socket
      ) do
    case Accounts.unsubscribe_from_emails(user) do
      {:ok, _user} ->
        update_subscribe_to_emails_in_parent(false)
        {:noreply, assign(socket, :updated, true)}

      _ ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Could not unsubscribe to emails. Please reload the page and try again."
         )}
    end
  end

  @impl true
  def handle_event("submit-subscription", _value, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("close-message", _params, socket) do
    {:noreply, assign(socket, :updated, false)}
  end

  defp assign_changeset(%{assigns: %{current_user: user}} = socket) do
    assign(socket, :changeset, User.email_subscription_changeset(user))
  end

  defp update_subscribe_to_emails_in_parent(subscribe_to_emails) do
    send(self(), {:current_user_updated, %{subscribe_to_emails: subscribe_to_emails}})
  end
end
