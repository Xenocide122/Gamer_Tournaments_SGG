defmodule StridentWeb.UserSettingsLive.ConfirmEmailComponent do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Auth

  @impl true
  def mount(socket) do
    socket
    |> assign(:email_sent_to, nil)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "click",
        _unsigned_params,
        %{assigns: %{current_user: %{password_credential: password_credential}}} = socket
      ) do
    case Auth.deliver_password_credential_confirmation_instructions(password_credential) do
      {:ok, %{to: to}} ->
        socket
        |> assign(:email_sent_to, to)
        |> then(&{:noreply, &1})

      {:ok, :already_confirmed} ->
        socket
        |> put_flash(:info, "You are already confirmed")
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(
          :error,
          "We were unable to deliver an email to #{password_credential.email}. Please contact us on Discord or support@stride.gg."
        )
        |> then(&{:noreply, &1})
    end
  end
end
