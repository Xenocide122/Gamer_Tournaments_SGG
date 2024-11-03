defmodule StridentWeb.Plugs.AssignRemoteIp do
  @moduledoc """
  Puts a Remote Ip from conn to conn.assigns
  """
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    ip =
      if Application.get_env(:strident, :env) in [:dev],
        do: Application.get_env(:strident, :my_ip_address, conn.remote_ip),
        else: conn.remote_ip

    assign(conn, :remote_ip, ip)
  end
end
