defmodule StridentWeb.AdminLive.Features.Edit do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Features
  alias Strident.Features.Feature
  alias StridentWeb.AdminLive.Features.Components.FeatureFormComponent

  def mount(%{"id" => id}, _session, socket) do
    feature = Features.get(id)

    socket
    |> assign(:changeset, Feature.changeset(feature))
    |> assign(:feature, feature)
    |> then(&{:ok, &1})
  end
end
