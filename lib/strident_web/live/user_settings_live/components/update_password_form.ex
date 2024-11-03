defmodule StridentWeb.UserSettingsLive.UpdatePasswordForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Auth
  alias Strident.Auth.PasswordCredential

  @impl true
  def mount(socket) do
    socket
    |> assign(%{
      current_password: nil,
      confirmation: false,
      trigger_password: false
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
        "validate_password",
        %{"password_credential" => attrs, "current_password" => current_password},
        socket
      ) do
    changeset =
      Auth.change_password_credential_password(
        %PasswordCredential{},
        Map.put_new(attrs, "password_confirmation", "")
      )

    {_, changeset} =
      if changeset.valid?,
        do: {:ok, changeset},
        else: Ecto.Changeset.apply_action(changeset, :validate)

    {:noreply, assign(socket, changeset: changeset, current_password: current_password)}
  end

  @impl true
  def handle_event(
        "update_password",
        %{"current_password" => password, "password_credential" => password_credential_params},
        socket
      ) do
    password_credential = Auth.get_password_credential_by_user_id(socket.assigns.current_user.id)

    changeset =
      Auth.test_update_password_credential_password(
        password_credential,
        password,
        password_credential_params
      )

    if changeset.valid? do
      {:noreply, assign(socket, trigger_password: true)}
    else
      {_, changeset} = Ecto.Changeset.apply_action(changeset, :update)
      {:noreply, assign(socket, changeset: changeset)}
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
    |> Auth.change_password_credential_password()
    |> then(&assign(socket, :changeset, &1))
  end
end
