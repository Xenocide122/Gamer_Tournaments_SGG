defmodule StridentWeb.UserLive.StatisticComponent do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{statistic: statistic}, socket) do
    {:ok, assign(socket, :statistic, statistic)}
  end
end
