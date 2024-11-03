defmodule StridentWeb.SegmentAnalyticsHelpers do
  @moduledoc """
  Conveniences for posting analytics events
  """
  alias StridentWeb.UserAuth
  alias Phoenix.LiveView.Socket
  alias Segment.Analytics
  alias Segment.Analytics.Context

  @type context() :: %Context{}

  @doc """
  Post a "tracked" event to Segment, using the current_user
  on the socket assigns to create the `segment_id`.

  It differs only in the first argument from `Segment.Analytics.track/4`
  """
  @spec track_segment_event(Socket.t(), String.t(), map(), context()) :: Socket.t()
  def track_segment_event(
        %Socket{} = socket,
        event_name,
        properties \\ %{},
        context \\ Context.new()
      ) do
    tap(socket, fn socket ->
      segment_id = UserAuth.user_segment_identifier(socket)
      Analytics.track(segment_id, event_name, properties, context)
    end)
  end
end
