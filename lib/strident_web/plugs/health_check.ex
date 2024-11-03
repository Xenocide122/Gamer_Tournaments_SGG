defmodule StridentWeb.Plugs.HealthCheck do
  @moduledoc """
  The HealthCheck Plug
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/health"} = conn, _opts) do
    conn
    |> send_resp(200, "")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
