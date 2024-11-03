defmodule StridentWeb.Plugs.ShowVPNBanner do
  @moduledoc """
    PLUG to determine if we should show the User that they are using a VPN
  """
  import Plug.Conn
  require Logger

  alias Strident.Location.Utils
  alias Strident.VPN

  def init(options), do: options

  def call(conn, _opts) do
    %{current_user: current_user, remote_ip: remote_ip} = conn.assigns

    remote_ip
    |> Utils.ip_to_string()
    |> VPN.show_vpn_banner?(current_user)
    |> tap(fn show_vpn_banner ->
      unless show_vpn_banner do
        VPN.hide_vpn_banner(current_user)
      end
    end)
    |> then(&assign(conn, :show_vpn_banner, &1))
  end
end
