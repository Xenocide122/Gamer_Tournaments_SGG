defmodule StridentWeb.Plugs.ReturnTo do
  @moduledoc """
  Puts a return to path into the session to use after the timezone
  confirmation. If the paths for login and impersonate are used they
  are ignored.
  """

  @behaviour Plug

  import Plug.Conn

  @ignore_paths ["/users/log_in", "/admin/impersonate"]
  @ignore_path_first_parts ["oauth2", "auth"]

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.request_path in @ignore_paths or
         List.first(conn.path_info) in @ignore_path_first_parts do
      conn
    else
      assign(conn, :user_return_to, conn.request_path)
    end
  end
end
