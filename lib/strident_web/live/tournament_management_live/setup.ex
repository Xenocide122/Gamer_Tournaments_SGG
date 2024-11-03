defmodule StridentWeb.TournamentManagment.Setup do
  @moduledoc false
  import Phoenix.LiveView
  import Phoenix.Component
  alias Strident.Accounts.User
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias StridentWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.Socket

  @stage_full_preloads [
    :settings,
    :child_edges,
    :children,
    :participants,
    matches: [
      :match_reports,
      :child_edges,
      :parent_edges,
      :parents,
      [participants: :tournament_participant]
    ]
  ]
  @full_preloads [
    :game,
    :social_media_links,
    :management_personnel,
    stages: @stage_full_preloads,
    participants: [
      tournament: [],
      players: :user,
      active_invitation: :user,
      team: [team_members: :user],
      party: [party_members: :user]
    ]
  ]

  @dashboard_preloads [
    :management_personnel,
    participants: [
      tournament: [],
      players: :user,
      active_invitation: :user,
      team: [team_members: :user],
      party: [party_members: :user]
    ]
  ]

  def tournament_full_preloads, do: @full_preloads
  def stage_full_preloads, do: @stage_full_preloads
  def tournament_dashboard_preloads, do: @dashboard_preloads

  def on_mount(:default, %{"slug" => slug}, _session, socket) do
    do_on_mount(socket, slug, social_media_links: [], participants: [:party])
  end

  def on_mount(:can_manage_tournament, %{"slug" => slug}, _session, socket) do
    do_can_manage_tournament(socket, slug)
  end

  def on_mount(:can_manage_tournament, :not_mounted_at_router, %{"slug" => slug}, socket) do
    do_can_manage_tournament(socket, slug)
  end

  def on_mount(
        :full,
        :not_mounted_at_router,
        %{"slug" => slug},
        socket
      ) do
    socket
    |> do_on_mount(slug, tournament_full_preloads())
  end

  def on_mount(:full, %{"slug" => slug}, _session, socket) do
    do_on_mount(socket, slug, tournament_full_preloads())
  end

  @spec do_on_mount(Socket.t(), String.t(), Keyword.t()) :: {:cont | :halt, Socket.t()}
  def do_on_mount(socket, slug, preloads) do
    tournament = Tournaments.get_tournament_with_preloads_by([slug: slug], preloads)

    if tournament == nil do
      socket
      |> put_flash(:info, "That tournament doesn't exist")
      |> redirect(to: Routes.tournament_index_path(socket, :index))
      |> then(&{:halt, &1})
    else
      socket
      |> assign(tournament: tournament)
      |> assign(slug: slug)
      |> then(&{:cont, &1})
    end
  end

  @spec do_can_manage_tournament(Socket.t(), String.t()) :: {:cont | :halt, Socket.t()}
  def do_can_manage_tournament(socket, slug) do
    tournament =
      case socket.assigns do
        %{tournament: %Tournament{} = tournament} -> tournament
        _ -> Tournaments.get_tournament_with_preloads_by(slug: slug)
      end

    case {tournament, Map.get(socket.assigns, :current_user)} do
      {_tournament, nil} ->
        socket
        |> assign(:can_manage_tournament, false)
        |> redirect(to: Routes.live_path(socket, StridentWeb.UserLogInLive))
        |> then(&{:halt, &1})

      {nil, _} ->
        socket
        |> assign(:can_manage_tournament, false)
        |> redirect(to: Routes.tournament_index_path(socket, :index))
        |> then(&{:halt, &1})

      {_tournament, %User{} = current_user} ->
        can_manage_tournament = Tournaments.can_manage_tournament?(current_user, tournament)

        socket
        |> assign(:can_manage_tournament, can_manage_tournament)
        |> then(&{:cont, &1})
    end
  end
end
