defmodule StridentWeb.TournamentSettingsLive.Components.BasicSettings do
  @moduledoc false
  use StridentWeb, :live_component
  alias Ecto.Changeset
  alias Strident.Games
  alias Strident.Tournaments

  @impl true
  def update(assigns, socket) do
    %{
      tournament: tournament,
      tournament_changeset: tournament_changeset,
      discord_sml_changeset: discord_sml_changeset,
      stream_sml_changesets: stream_sml_changesets,
      mgmt_changesets: mgmt_changesets,
      mgmt_search_results: mgmt_search_results
    } = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:is_connected, connected?(socket))
    |> assign(:tournament, tournament)
    |> assign(:tournament_changeset, tournament_changeset)
    |> assign(:discord_sml_changeset, discord_sml_changeset)
    |> assign(:stream_sml_changesets, stream_sml_changesets)
    |> assign(:mgmt_changesets, mgmt_changesets)
    |> assign(:mgmt_search_results, mgmt_search_results)
    |> assign(:cancelled, tournament.status == :cancelled)
    |> assign(:form, to_form(%{}, as: :new_mgmt))
    |> assign_games()
    |> assign_platforms()
    |> then(&{:ok, &1})
  end

  def assign_games(socket) do
    case socket.assigns do
      %{games: games} when is_list(games) ->
        socket

      _ ->
        Games.list_games()
        |> Enum.map(&{&1.title, &1.id})
        |> then(&assign(socket, :games, &1))
    end
  end

  def assign_platforms(socket) do
    case socket.assigns do
      %{platforms: platforms} when is_list(platforms) ->
        socket

      _ ->
        Tournaments.Tournament
        |> Ecto.Enum.mappings(:platform)
        |> Enum.map(fn {value, key} -> {key, value} end)
        |> then(&assign(socket, :platforms, &1))
    end
  end
end
