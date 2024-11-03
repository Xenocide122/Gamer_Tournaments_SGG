defmodule StridentWeb.UserSettingsLive.Components.DeleteAccountComponent do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias StridentWeb.Endpoint
  alias Phoenix.LiveView.JS

  @delete_me_text "F in the Chat"

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:disable_delete_account_button, true)
    |> assign(:trigger_submit, false)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("validate-delete-me-text", %{"delete_me_text" => params}, socket) do
    socket
    |> assign(:disable_delete_account_button, !(@delete_me_text == params["input"]))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("validate-delete-me-text", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("actual-delete-account", _params, socket) do
    %{assigns: %{current_user: current_user}} = socket

    with %{assigns: %{disable_delete_account_button: false}} <- socket,
         {:ok, _user} <- Accounts.delete_account(current_user) do
      socket
      |> put_flash(:info, "You have successfully deleted your account!")
      |> assign(:trigger_submit, true)
      |> then(&{:noreply, &1})
    else
      %{assigns: %{disable_delete_account_button: true}} ->
        socket
        |> put_flash(:error, "You first need to write text in the form!")
        |> then(&{:noreply, &1})

      {:error, _account} ->
        socket
        |> put_flash(:error, "Error deleting your account! Please contact support.")
        |> then(&{:noreply, &1})
    end
  end
end
