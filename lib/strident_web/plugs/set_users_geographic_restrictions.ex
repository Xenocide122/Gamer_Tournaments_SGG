defmodule StridentWeb.Plugs.SetUsersGepographicRestrictions do
  @moduledoc false

  @behaviour Plug
  import Plug.Conn
  alias Strident.GeographicWhitelists

  def init(opts), do: opts

  def call(conn, _opts) do
    %{
      ip_location: ip_location,
      is_using_vpn: is_using_vpn
    } = conn.assigns

    can_stake =
      ip_location != nil and not is_using_vpn and
        GeographicWhitelists.location_whitelisted?(ip_location, :stake)

    can_play =
      ip_location != nil and not is_using_vpn and
        GeographicWhitelists.location_whitelisted?(ip_location, :play)

    can_wager =
      ip_location != nil and not is_using_vpn and
        GeographicWhitelists.location_whitelisted?(ip_location, :wager)

    conn
    |> assign(:can_stake, can_stake)
    |> assign(:can_play, can_play)
    |> assign(:can_wager, can_wager)
  end
end
