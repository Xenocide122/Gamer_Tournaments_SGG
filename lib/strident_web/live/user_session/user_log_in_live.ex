defmodule StridentWeb.UserLogInLive do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Auth
  alias Strident.Auth.PasswordCredential

  def mount(params, _session, socket) do
    show_apple_login = Map.get(params, "show_apple_login") == "true"

    changeset = PasswordCredential.login_changeset(%PasswordCredential{}, %{})

    socket =
      assign(socket,
        page_title: "Log In",
        changeset: changeset,
        trigger_login: false,
        invalid_login: false,
        show_apple_login: show_apple_login,
        user_return_to: params["user_return_to"] || nil
      )

    {:ok, socket, layout: {StridentWeb.LayoutView, :live}}
  end

  def handle_event("validate", %{"user" => attrs}, socket) do
    changeset =
      PasswordCredential.login_changeset(
        %PasswordCredential{},
        attrs
      )

    {_, changeset} =
      if changeset.valid?,
        do: {:ok, changeset},
        else: Ecto.Changeset.apply_action(changeset, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("login", %{"user" => attrs}, socket) do
    %{"email" => email, "password" => password} = attrs

    if Auth.get_password_credential_by_email_and_password(email, password) do
      {:noreply, assign(socket, :trigger_login, true)}
    else
      changeset = PasswordCredential.login_changeset(%PasswordCredential{}, attrs)

      {_, changeset} =
        if changeset.valid?,
          do: {:ok, changeset},
          else: Ecto.Changeset.apply_action(changeset, :validate)

      {:noreply, assign(socket, changeset: changeset, invalid_login: true)}
    end
  end
end
