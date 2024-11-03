defmodule StridentWeb.Plugs.IpLocation do
  @moduledoc """
  Puts IP-derived location on the assigns
  """
  @behaviour Plug

  require Logger
  import Plug.Conn
  alias Strident.Accounts.User
  alias Strident.GeoLocation
  alias Strident.Location.Utils

  def init(opts), do: opts

  def call(conn, _opts) do
    ip_location = get_ip_location(conn)
    user = conn.assigns.current_user
    remote_ip = conn.assigns.remote_ip
    maybe_write_event_record(user, remote_ip, ip_location)
    maybe_create_or_update_region_code_count(user, ip_location)
    assign(conn, :ip_location, ip_location)
  end

  @spec maybe_write_event_record(User.t() | nil, String.t() | tuple(), map()) :: Task.t() | :ok
  def maybe_write_event_record(nil, _remote_ip, _ip_location), do: :ok

  def maybe_write_event_record(user, remote_ip, ip_location) when is_tuple(remote_ip),
    do: maybe_write_event_record(user, Utils.ip_to_string(remote_ip), ip_location)

  def maybe_write_event_record(user, remote_ip, ip_location) do
    Task.Supervisor.async_nolink(
      {:via, PartitionSupervisor, {Strident.IpLocationTaskSupervisor, self()}},
      fn ->
        GeoLocation.create_ip_location_event(%{
          user_id: user.id,
          remote_ip: remote_ip,
          region_code: ip_location.region_code,
          country_code: ip_location.country_code
        })
      end
    )
  end

  @spec maybe_create_or_update_region_code_count(User.t() | nil, map()) :: Task.t() | :ok
  def maybe_create_or_update_region_code_count(nil, _ip_location), do: :ok

  def maybe_create_or_update_region_code_count(user, ip_location) do
    Task.Supervisor.async_nolink(
      {:via, PartitionSupervisor, {Strident.IpLocationRegionCountTaskSupervisor, self()}},
      fn ->
        GeoLocation.create_or_update_region_code_count(%{
          user_id: user.id,
          region_code: ip_location.region_code
        })
      end
    )
  end

  @spec get_ip_location(Plug.Conn.t()) :: map()
  defp get_ip_location(%{assigns: %{is_bot: false}} = conn) do
    %{remote_ip: remote_ip, user_agent: user_agent} = conn.assigns

    case GeoLocation.get_geolcation(remote_ip, user_agent) do
      {:ok, location} ->
        location

      _ ->
        %{
          country_code: "nan",
          region_name: "nan",
          country_name: "Invalid",
          region_code: "nan",
          locale: "en-US",
          timezone: "UTC"
        }
    end
  end

  defp get_ip_location(_conn), do: nil
end
