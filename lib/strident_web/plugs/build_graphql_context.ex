defmodule StridentWeb.Plugs.BuildGraphqlContext do
  @moduledoc """
  This Phoenix Plug extracts a Bearer token from the HTTP header
  and if it finds a user with that token, applies the user to the
  conn.context. This conn.context is used by the GraphqlAuthentication
  module.
  """

  @behaviour Plug

  @keys [
    :current_user,
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
    :is_mobile
  ]

  def init(opts), do: opts

  def call(conn, _opts) do
    context = Map.take(conn.assigns, @keys)
    Absinthe.Plug.put_options(conn, context: context)
  end
end
