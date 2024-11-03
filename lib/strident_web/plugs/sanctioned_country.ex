defmodule StridentWeb.Plugs.SanctionedCountry do
  @moduledoc """
  Returns a 403 Forbidden status code if the user comes
  from a sanctioned country.
  """
  @behaviour Plug

  import Plug.Conn

  # Belarus, Cuba, China, Iran, Korea, Russia, Syria
  @blocked_countries ["BY", "CU", "CN", "IR", "KP", "RU", "SY"]

  def init(opts), do: opts

  def call(conn, _opts) do
    country =
      case get_session(conn, "ip_location") do
        ip_location when is_map(ip_location) -> Map.get(ip_location, :country_code)
        _ -> nil
      end

    if country in @blocked_countries do
      conn
      |> put_status(403)
      |> send_resp(403, "Forbidden")
      |> halt()
    else
      conn
    end
  end
end
