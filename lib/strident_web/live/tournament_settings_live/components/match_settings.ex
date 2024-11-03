defmodule StridentWeb.TournamentSettingsLive.Components.MatchSettings do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Stages.StageSetting

  @impl true
  def update(assigns, socket) do
    %{tournament: tournament, stage_setting_changesets: stage_setting_changesets} = assigns

    socket
    |> assign(:is_connected, connected?(socket))
    |> assign(:tournament, tournament)
    |> assign(:cancelled, tournament.status == :cancelled)
    |> assign(:stage_setting_changesets, stage_setting_changesets)
    |> then(&{:ok, &1})
  end

  @sort_order [
    :notify_participant_when_tournament_starts,
    :participant_can_report_scores
  ]
  defp sort_order(name), do: Enum.find_index(@sort_order, &(&1 == name))

  defp capitalize_each_word(atom) do
    atom
    |> humanize()
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp label_string(:notify_participant_when_tournament_starts) do
    "Notify Participant When They Can Check-in To Their Match"
  end

  defp label_string(setting_name) do
    capitalize_each_word(setting_name)
  end
end
