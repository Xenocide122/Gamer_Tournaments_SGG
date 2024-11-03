defmodule StridentWeb.Plugs.BotDetector do
  @moduledoc """
  Puts an `is_bot` boolean on the Conn assigns
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    is_bot = is_conn_bot?(conn)
    assign(conn, :is_bot, is_bot)
  end

  @spec is_conn_bot?(Plug.Conn.t()) :: boolean()
  defp is_conn_bot?(%{assigns: %{user_agent: "Render/1.0"}}), do: true
  defp is_conn_bot?(%{assigns: %{user_agent: nil}}), do: false

  defp is_conn_bot?(%{assigns: %{user_agent: user_agent}}) when is_binary(user_agent),
    do: user_agent |> String.downcase() |> String.contains?(["bot", "curl", "wget"])

  defp is_conn_bot?(_conn), do: false
end
