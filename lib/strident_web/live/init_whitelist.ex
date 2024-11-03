defmodule StridentWeb.Live.InitWhitelist do
  @moduledoc """
  Make sure the user has any play/stake/wager permission for tournaments.
  """
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont, socket}
  end

  def on_mount(:redirect_unless_whitelisted, _params, _session, socket) do
    _can_play = get_assign_as_boolean(socket, :can_play)
    _can_stake = get_assign_as_boolean(socket, :can_stake)
    _can_wager = get_assign_as_boolean(socket, :can_wager)

    {:cont, socket}
  end

  defp halt_with_error(socket) do
    ip_location = Map.get(socket.assigns, :ip_location)

    error_message =
      case ip_location do
        %{region_name: region_name, country_code: country_code} ->
          "Sorry you are unable to access this page from #{region_name}, #{country_code}"

        _ ->
          "Sorry you are unable to access this page"
      end

    socket
    |> put_flash(:error, error_message)
    |> redirect(to: "/")
    |> then(&{:halt, &1})
  end

  defp get_assign_as_boolean(socket, assigns_key), do: !!Map.get(socket.assigns, assigns_key)
end
