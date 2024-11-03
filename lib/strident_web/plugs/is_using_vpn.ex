defmodule StridentWeb.Plugs.IsUsingVpn do
  @moduledoc """
    Plug to record when a User is using a known VPN. If there is
    an error when checking the IPHub vpn status the value defaults
    to false
  """

  import Plug.Conn

  alias Strident.Location.Utils
  alias Strident.VPN

  def init(options), do: options

  def call(conn, _opts) do
    %{current_user: current_user, remote_ip: remote_ip} = conn.assigns

    remote_ip
    |> Utils.ip_to_string()
    |> VPN.is_known_vpn?(current_user)
    |> then(&assign(conn, :is_using_vpn, &1))
  end
end
