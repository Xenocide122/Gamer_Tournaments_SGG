defmodule StridentWeb.Components.TournamentCard do
  @moduledoc """
  Tournament card
  """
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{
          id: id,
          link_to: link_to,
          image_url: image_url,
          title: title,
          status: status,
          starts_at: starts_at,
          buy_in_amount: buy_in_amount,
          participants: participants,
          game_id: game_id
        } = assigns,
        socket
      ) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      id: id,
      link_to: link_to,
      image_url: image_url,
      title: title,
      starts_at: starts_at,
      buy_in_amount: buy_in_amount,
      participants: participants,
      game_id: game_id
    })
    |> assign(:label_text, label_text(status))
    |> assign(:call_to_action, call_to_action(status))
    |> assign(:call_to_action_classes, call_to_action_classes(status))
    |> then(&{:ok, &1})
  end

  defp label_text(:scheduled), do: "Contributions open soon"
  defp label_text(:registrations_open), do: "Entry fees open"
  defp label_text(:in_progress), do: "Live tournament"
  defp label_text(:under_review), do: "Completed tournament"
  defp label_text(:finished), do: "Completed tournament"
  defp label_text(:cancelled), do: "Cancelled tournament"

  defp call_to_action(:scheduled), do: "See details"
  defp call_to_action(:registrations_open), do: "Contribute"
  defp call_to_action(:in_progress), do: "Watch now"
  defp call_to_action(:under_review), do: "See details"
  defp call_to_action(:finished), do: "See details"
  defp call_to_action(:cancelled), do: "See details"

  defp call_to_action_classes(:scheduled), do: "btn btn--block btn--primary mt-6 uppercase"

  defp call_to_action_classes(:registrations_open),
    do: "btn btn--block btn--primary mt-6 uppercase"

  defp call_to_action_classes(:in_progress), do: "btn btn--block btn--primary mt-6 uppercase"

  defp call_to_action_classes(:under_review),
    do: "btn btn--block btn--primary-ghost mt-6 uppercase"

  defp call_to_action_classes(:finished), do: "btn btn--block btn--primary mt-6 uppercase"
  defp call_to_action_classes(:cancelled), do: "btn btn--block btn--primary mt-6 uppercase"
end
