defmodule StridentWeb.GiveawayLive.Index do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Extension.DateTime
  alias Strident.Extension.NaiveDateTime
  alias Strident.Games
  alias Strident.StringUtils
  alias Strident.Giveaway
  alias StridentWeb.SegmentAnalyticsHelpers

  on_mount({StridentWeb.InitAssigns, :default})

  @default_timezone Application.compile_env(:strident, :default_timezone)

end
