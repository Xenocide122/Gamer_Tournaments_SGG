defmodule StridentWeb.Plugs.BuildSession do
  @moduledoc """
  Builds session using the conn assigns
  """

  @behaviour Plug

  @keys [
    :remote_ip,
    :user_agent,
    :is_bot,
    :ip_location,
    :user_return_to,
    :is_using_vpn,
    :show_vpn_banner,
    :can_stake,
    :can_play,
    :can_wager,
    :is_mobile,
    :feature_popups
  ]

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    for {key, value} <- Map.take(conn.assigns, @keys), reduce: conn do
      conn -> put_session(conn, key, value)
    end
  end
end
