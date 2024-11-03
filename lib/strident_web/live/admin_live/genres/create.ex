defmodule StridentWeb.GenresLive.Create do
  @moduledoc false
  use StridentWeb, :live_view

  def mount(_params, _session, socket) do
    socket
    |> then(&{:ok, &1})
  end
end
