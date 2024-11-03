defmodule StridentWeb.TeamTournamentsLive.Components.TournamentParticipantModal do
  @moduledoc """
  Tournament Participant Modal
  """
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.Extension.NaiveDateTime
  alias Strident.Teams

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{tournament: tournament, team: team}, socket) do
    socket
    |> assign(:tournament, tournament)
    |> assign(:team, team)
    |> assign_tournament_participant_roster()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "add-roster-player",
        %{"user" => user_id},
        %{assigns: %{tournament: tournament, team: team}} = socket
      ) do
    case Teams.add_player_to_tournament_roster(user_id, tournament, team) do
      {:ok, player} ->
        user = Accounts.get_user(user_id)

        socket
        |> update(:roster, fn roster -> [%{user | players: [player]} | roster] end)
        |> then(&{:noreply, &1})

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Cannot add user to roster")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("remove-roster-player", %{"player" => player_id}, socket) do
    case Teams.remove_player_from_tournament_roster(player_id) do
      {:ok, player} ->
        socket
        |> update(:roster, fn roster -> Enum.reject(roster, &(&1.id == player.user_id)) end)
        |> then(&{:noreply, &1})

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Cannot add user to roster")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event(
        "make-starter",
        %{"player" => player_id},
        %{assigns: %{roster: roster}} = socket
      ) do
    case Teams.make_player_starter(player_id) do
      {:ok, player} ->
        new_roster =
          Enum.map(roster, fn
            %{players: [%{id: id}]} = user when id == player_id ->
              %{user | players: [player]}

            user ->
              user
          end)

        socket
        |> update(:roster, fn _ -> new_roster end)
        |> then(&{:noreply, &1})

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Cannot make player starter")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("make-sub", %{"player" => player_id}, %{assigns: %{roster: roster}} = socket) do
    case Teams.make_player_substitute(player_id) do
      {:ok, player} ->
        new_roster =
          Enum.map(roster, fn
            %{players: [%{id: id}]} = user when id == player_id ->
              %{user | players: [player]}

            user ->
              user
          end)

        socket
        |> update(:roster, fn _ -> new_roster end)
        |> then(&{:noreply, &1})

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Cannot make player substitute")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event(
        "toggle-captain",
        params,
        %{assigns: %{team: team, tournament: tournament, roster: roster}} = socket
      ) do
    with "player" <- Map.get(params, "type"),
         player_id <- Map.get(params, "player"),
         {:ok, %{captain_player: player}} <-
           Teams.make_player_captain(player_id, tournament, team) do
      new_roster =
        Enum.map(roster, fn
          %{players: [%{id: id}]} = user when id == player_id ->
            %{user | players: [player]}

          user ->
            player = user.players |> Enum.at(0) |> Map.put(:type, :player)
            %{user | players: [player]}
        end)

      socket
      |> update(:roster, fn _ -> new_roster end)
      |> then(&{:noreply, &1})
    else
      "captain" ->
        new_captain_id =
          Enum.reduce_while(roster, nil, fn
            %{players: [%{id: id, type: :player}]}, _val -> {:halt, id}
            _, val -> {:cont, val}
          end)

        {:ok, %{captain_player: player}} =
          Teams.make_player_captain(new_captain_id, tournament, team)

        new_roster =
          Enum.map(roster, fn
            %{players: [%{id: id}]} = user when id == new_captain_id ->
              %{user | players: [player]}

            user ->
              player = user.players |> Enum.at(0) |> Map.put(:type, :player)
              %{user | players: [player]}
          end)

        socket
        |> update(:roster, fn _ -> new_roster end)
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "Cannot make change players type")
        |> then(&{:noreply, &1})
    end
  end

  def handle_event(
        "validate-participant-stake",
        %{"participant_stake" => %{"stake_percentage" => split_raw}},
        %{assigns: %{tournament: tournament, team: _team}} = socket
      ) do
    with {stake, _} <- Integer.parse(split_raw),
         true <- get_mininum_split_stake(tournament) <= stake,
         true <- 100 >= stake do
      #  {:ok, _new_stake} <- Teams.update_tournament_stake(tournament, team, stake) do
      socket
      |> assign(:stake_percentage, split_raw)
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> assign(:stake_percentage, split_raw)
        |> then(&{:noreply, &1})
    end
  end

  def assign_tournament_participant_roster(
        %{assigns: %{team: team, tournament: tournament}} = socket
      ) do
    assign(socket, :roster, Teams.get_teams_tournament_roster(team, tournament))
  end

  def get_mininum_split_stake(_tournament) do
    0
  end

  defp is_future?(datetime) do
    NaiveDateTime.compare(datetime, NaiveDateTime.utc_now()) == :gt
  end
end
