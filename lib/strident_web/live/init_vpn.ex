defmodule StridentWeb.Live.VpnSessionLive do
  @moduledoc false
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont, socket}
  end

  def on_mount(:redirect_vpn_user, _params, session, socket) do
    if session["is_using_vpn"] do
      socket
      |> put_flash(:error, "Sorry you are unable to access this page while using a VPN")
      |> redirect(to: "/")
      |> then(&{:halt, &1})
    else
      {:cont, socket}
    end
  end
end
