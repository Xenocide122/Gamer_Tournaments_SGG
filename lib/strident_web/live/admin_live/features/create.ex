defmodule StridentWeb.AdminLive.Features.Create do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Features.Feature
  alias StridentWeb.AdminLive.Features.Components.FeatureFormComponent

  def mount(_params, _session, socket) do
    socket
    |> assign(changeset: Feature.changeset(%Feature{}))
    |> then(&{:ok, &1})
  end
end
