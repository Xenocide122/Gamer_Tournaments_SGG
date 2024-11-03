defmodule StridentWeb.Live.Components.NewFeaturePopups do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Features
  alias Phoenix.LiveView.JS

  @impl true
  def update(%{activate_popup: true} = assigns, socket) do
    %{features: features, title: title, description: description} = assigns

    socket
    |> assign(:features, features)
    |> assign(:current_feature, Enum.at(features, 0))
    |> assign(:features_title, title)
    |> assign(:features_description, description)
    |> then(&{:ok, &1})
  end

  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(:id, "new-features-popup")
    |> assign(:features, [])
    |> assign(:current_feature, %{})
    |> assign(:features_title, nil)
    |> assign(:features_description, nil)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("go-to-feature", %{"feature" => id}, socket) do
    %{features: features} = socket.assigns

    case Enum.find(features, &(&1.id == id)) do
      nil -> socket
      feature -> assign(socket, :current_feature, feature)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("do-not-show-again", _params, socket) do
    %{features: features, current_user: current_user} = socket.assigns
    Features.mark_features_read(current_user, features)

    {:noreply, socket}
  end
end
