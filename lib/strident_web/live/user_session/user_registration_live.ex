defmodule StridentWeb.UserRegistrationLive do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.Auth.Captcha

  @prod_env Application.compile_env(:strident, :env) == :prod

  def mount(_params, _session, socket) do
    changeset = Accounts.change_password_credential_registration(%User{})

    socket =
      assign(socket,
        page_title: "Register",
        changeset: changeset,
        suggested_name: nil,
        trigger_login: false,
        show_all_errors: false,
        captcha_error: false,
        show_apple_login: false
      )

    {:ok, socket}
  end

  defp create_user_valid(socket, changeset, opts) do
    if @prod_env and Keyword.get(opts, :needs_captcha, true) do
      push_event(socket, "create_captcha", %{sitekey: Captcha.sitekey()})
    else
      assign(socket, changeset: changeset, trigger_login: changeset.valid?)
    end
  end

  def handle_event("create", %{"user" => attrs, "h-captcha-response" => h_captcha}, socket) do
    case Captcha.verify(h_captcha) do
      {:ok, _response} ->
        {:noreply, create_user(socket, attrs, needs_captcha: false)}

      {:error, _errors} ->
        {:noreply,
         socket
         |> push_event("create_captcha", %{sitekey: Captcha.sitekey()})
         |> assign(:captcha_error, true)}
    end
  end

  def handle_event("validate", %{"user" => attrs}, socket) do
    {:noreply, assign(socket, Accounts.suggest_display_name_for_registration(attrs))}
  end

  def handle_event("create", %{"user" => attrs}, socket) do
    {:noreply, create_user(socket, attrs)}
  end

  defp create_user(socket, attrs, opts \\ [])

  defp create_user(
         socket,
         %{"display_name" => display_name, "password_credential" => %{"email" => email}} = attrs,
         opts
       )
       when bit_size(display_name) == 0 do
    generated_display_name = Accounts.display_name_from_email(email)
    attrs_with_display_name = Map.put(attrs, "display_name", generated_display_name)
    create_user(socket, attrs_with_display_name, opts)
  end

  defp create_user(socket, attrs, opts) do
    changeset = User.password_credential_registration_changeset(%User{}, attrs)

    if changeset.valid? do
      create_user_valid(socket, changeset, opts)
    else
      {:error, changeset} = Ecto.Changeset.apply_action(changeset, :validate)

      assign(socket, changeset: changeset, show_all_errors: true)
    end
  end
end
