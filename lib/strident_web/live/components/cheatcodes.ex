defmodule StridentWeb.Components.Cheatcodes do
  @moduledoc """
  Cheatcodes component
  """
  require Logger
  use StridentWeb, :live_component
  alias StridentWeb.Components.Cheatcodes.Data

  def mount(socket) do
    socket
    |> push_key_codes()
    |> assign(:konami, false)
    |> then(&{:ok, &1})
  end

  def handle_event("start_cheat_konami", _, %{assigns: %{konami: false}} = socket) do
    Logger.info("Someone started the konami cheat!", lm(socket))

    socket
    |> push_event("start_cheat_konami", %{})
    |> assign(:konami, true)
    |> then(&{:noreply, &1})
  end

  def handle_event("start_cheat_konami", _, socket), do: {:noreply, socket}

  def handle_event("stop_cheat_konami", _, %{assigns: %{konami: true}} = socket) do
    Logger.info("Someone stopped the konami cheat.", lm(socket))

    socket
    |> push_event("stop_cheat_konami", %{})
    |> assign(:konami, false)
    |> then(&{:noreply, &1})
  end

  def handle_event("clear_cookies", _, socket) do
    Logger.info("Someone cleared cookies!", lm(socket))

    socket
    |> push_event("clear_cookies", %{})
    |> then(&{:noreply, &1})
  end

  defp push_key_codes(socket) do
    is_connected = connected?(socket)

    if is_connected do
      key_codes = Data.key_codes()
      push_event(socket, "psst_here_are_the_cheatcodes", %{key_codes: key_codes})
    else
      socket
    end
  end

  defp lm(socket) do
    user_id =
      case socket.assigns do
        %{current_user: %{id: id}} -> id
        _ -> nil
      end

    %{user_id: user_id}
  end
end
