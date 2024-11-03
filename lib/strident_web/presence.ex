defmodule StridentWeb.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :strident,
    pubsub_server: Strident.PubSub

  alias StridentWeb.Presence

  def track_presence(pid, topic, key, payload) do
    Presence.track(pid, topic, key, payload)
  end

  def update_presence(pid, topic, key, payload) do
    metas =
      Presence.get_by_key(topic, key)[:metas]
      |> List.first()
      |> Map.merge(payload)

    Presence.update(pid, topic, key, metas)
  end

  def list_presences(topic) do
    topic
    |> Presence.list()
    |> Enum.map(fn {_user_id, data} ->
      List.first(data[:metas])
    end)
  end
end
