defmodule StridentWeb.Plugs.UserAgent do
  @moduledoc false
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_agent = get_user_agent(conn)
    Logger.metadata(user_agent: user_agent)
    assign(conn, :user_agent, user_agent)
  end

  @spec get_user_agent(Plug.Conn.t()) :: String.t() | nil
  defp get_user_agent(conn) do
    # Copied from `Phoenix.Socket.Transport.fetch_user_agent/1`
    # the Plug.Conn docs say "all headers will be downcased"
    with {_, value} <- List.keyfind(conn.req_headers, "user-agent", 0) do
      value
    end
  end
end
