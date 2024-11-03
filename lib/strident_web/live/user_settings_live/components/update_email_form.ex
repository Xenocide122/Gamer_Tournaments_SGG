defmodule StridentWeb.UserSettingsLive.UpdateEmailForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Auth
  alias Strident.Auth.PasswordCredential

  @impl true
  def mount(socket) do
    socket
    |> assign(%{
      current_password: nil,
      confirmation: false
    })
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
        "validate_email",
        %{"password_credential" => attrs, "current_password" => curr},
        socket
      ) do
    %PasswordCredential{:email => email} =
      Auth.get_password_credential_by_user_id(socket.assigns.current_user.id)

    changeset =
      %PasswordCredential{email: email}
      |> Auth.change_password_credential_email(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset, current_password: curr)}
  end

  @impl true
  def handle_event(
        "update_email",
        %{"current_password" => password, "password_credential" => password_credential_params},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    password_credential = Auth.get_password_credential_by_user_id(current_user.id)

    case Auth.apply_password_credential_email(
           password_credential,
           password,
           password_credential_params
         ) do
      {:ok, applied_password_credential} ->
        Auth.deliver_update_email_instructions(
          applied_password_credential,
          password_credential.email
        )

        socket
        |> assign(confirmation: true)
        |> track_segment_event("Email Address Updated")
        |> then(fn socket -> {:noreply, socket} end)

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, confirmation: false)}
    end
  end

  defp assign_changeset(
         %{
           assigns: %{
             current_user: %{password_credential: %PasswordCredential{} = password_credential}
           }
         } = socket
       ) do
    password_credential
    |> Auth.change_password_credential_email(%{email: ""})
    |> then(&assign(socket, :changeset, &1))
  end
end
