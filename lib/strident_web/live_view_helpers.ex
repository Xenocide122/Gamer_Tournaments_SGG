defmodule StridentWeb.LiveViewHelpers do
  @moduledoc """
  Useful functions accessible in any LiveView or LiveComponent
  """
  alias Strident.Accounts
  alias StridentWeb.ErrorHelpers
  alias Phoenix.Component
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @doc """
  A convenience function to close the confirmation component.

  It sets all the usual assigns to nil.
  """
  @spec close_confirmation(Socket.t()) :: Socket.t()
  def close_confirmation(socket) do
    Component.assign(socket, %{
      show_confirmation: false,
      confirmation_confirm_event: nil,
      confirmation_confirm_values: nil,
      confirmation_message: nil,
      confirmation_confirm_prompt: nil,
      confirmation_cancel_prompt: nil
    })
  end

  @spec put_error_on_flash(Socket.t(), Ecto.Changeset.t() | binary()) :: Socket.t()
  def put_error_on_flash(socket, error) when is_binary(error) do
    LiveView.put_flash(socket, :error, error)
  end

  def put_error_on_flash(socket, %Ecto.Changeset{} = changeset) do
    ErrorHelpers.put_humanized_changeset_errors_in_flash(socket, changeset)
  end

  @doc """
  Assign `:debug_mode` bool if current_user is staff and URL has `?debug_mode=true`
  """
  @spec assign_debug_mode(Socket.t(), map, map) :: Socket.t()
  def assign_debug_mode(socket, params, session),
    do: Component.assign(socket, :debug_mode, enable_debug_mode?(socket, params, session))

  @spec enable_debug_mode?(Socket.t(), map, map) :: boolean
  defp enable_debug_mode?(
         %{assigns: %{current_user: %{is_staff: true}}},
         %{
           "debug_mode" => debug_mode
         },
         _session
       )
       when debug_mode in [true, "true"],
       do: true

  defp enable_debug_mode?(%{assigns: %{current_user: %{is_staff: true}}}, _params, %{
         "debug_mode" => debug_mode
       })
       when debug_mode in [true, "true"],
       do: true

  defp enable_debug_mode?(_socket, _params, _session), do: false

  def assign_current_user_from_session_token(socket, session) do
    current_user =
      case Map.get(session, "user_token") do
        nil -> nil
        token when is_binary(token) -> Accounts.get_user_by_session_token(token)
      end

    Component.assign_new(socket, :current_user, fn _ -> current_user end)
  end
end
