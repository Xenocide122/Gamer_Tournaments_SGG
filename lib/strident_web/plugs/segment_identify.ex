defmodule StridentWeb.Plugs.SegmentIdentify do
  @moduledoc false
  @behaviour Plug
  alias Strident.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    tap(conn, &identify/1)
  end

  @spec identify(Plug.Conn.t()) :: :ok | nil
  defp identify(%{assigns: %{is_bot: false}} = conn) do
    user = conn.assigns[:current_user]

    if user do
      Segment.Analytics.identify(user.id, %{
        email: Accounts.user_email_assured(user),
        avatar: user.avatar_url,
        name: user.display_name,
        ip: ip_string(conn.remote_ip)
      })
    end
  end

  defp identify(_conn), do: nil

  defp ip_string(remote_ip) when is_tuple(remote_ip) do
    remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp ip_string(remote_ip), do: remote_ip
end
