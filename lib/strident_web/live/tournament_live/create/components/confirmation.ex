defmodule StridentWeb.TournamentLive.Create.Confirmation do
  @moduledoc """
  The "confirmation" form page, where user provides details.
  """
  use StridentWeb, :live_component
  alias Strident.Prizes

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(
        %{
          f: f,
          stages: stages,
          tournament_type: tournament_type,
          stages_structure: stages_structure,
          tournament_info: tournament_info,
          invites: invites,
          confirmation: confirmation,
          games: games,
          platforms: platforms,
          locations: locations,
          invited_users: invited_users
        } = assigns,
        socket
      ) do
    stage_types = Enum.map_join(stages.types, " → ", &humanize/1)
    game_title = Enum.find(games, &(&1.id == tournament_info.game_id)).title
    platform = Keyword.get(platforms, tournament_info.platform)
    location = Keyword.get(locations, tournament_info.location)

    {registered_users, will_be_invited} =
      invites.emails
      |> Enum.with_index(1)
      |> Enum.reject(fn
        {nil, _seed_index} -> true
        {"", _seed_index} -> true
        _ -> false
      end)
      |> Enum.reduce({[], []}, fn {email, seed_index}, {users, emails} ->
        case Enum.find(invited_users, &(&1.email == email)) do
          nil -> {users, [{email, seed_index} | emails]}
          user -> {[{user, seed_index} | users], emails}
        end
      end)

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:f, f)
    |> assign(%{game_title: game_title, platform: platform, location: location})
    |> assign(%{
      registered_users: Enum.reverse(registered_users),
      will_be_invited: Enum.reverse(will_be_invited)
    })
    |> assign(:stage_types, stage_types)
    |> assign(:tournament_type, tournament_type)
    |> assign(:stages_structure, stages_structure)
    |> assign(:tournament_info, tournament_info)
    |> assign(:confirmation, confirmation)
    |> then(&{:ok, &1})
  end
end
