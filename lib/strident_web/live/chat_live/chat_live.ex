defmodule StridentWeb.ChatLive do
  @moduledoc false
  use StridentWeb, :live_view
  import Strident.ChatLive.DeadView
  alias Strident.Accounts
  alias Strident.Chats.Message
  alias Strident.Matches
  alias Strident.Matches.Match
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Strident.Tournaments.Tournament
  alias StridentWeb.Presence

  @preloads [
    created_by: [],
    management_personnel: [user: []],
    stages: [
      matches: [chat: [:messages], participants: [tournament_participant: [players: [user: []]]]]
    ]
  ]

  @impl true
  def mount(:not_mounted_at_router, session, socket) do
    %{
      "timezone" => timezone,
      "locale" => locale,
      "can_stake" => can_stake,
      "can_play" => can_play,
      "can_wager" => can_wager,
      "is_using_vpn" => is_using_vpn,
      "show_vpn_banner" => show_vpn_banner
    } = session

    socket = assign_current_user_from_session_token(socket, session)

    check_timezone =
      if socket.assigns.current_user do
        socket.assigns.current_user.check_timezone
      else
        false
      end

    socket
    |> assign_current_user_from_session_token(session)
    |> assign(:timezone, timezone)
    |> assign(:locale, locale)
    |> assign(:can_stake, can_stake)
    |> assign(:can_play, can_play)
    |> assign(:can_wager, can_wager)
    |> assign(:is_using_vpn, is_using_vpn)
    |> assign(:show_vpn_banner, show_vpn_banner)
    |> assign(:check_timezone, check_timezone)
    |> do_mount(%{}, session)
  end

  def mount(params, session, socket) do
    do_mount(socket, params, session)
  end

  @impl true
  def handle_event("select-chat-room", %{"chat" => room_name}, socket) do
    socket
    |> assign(:selected_chat_room, room_name)
    |> assign_selected_chat()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("send-message", %{"message" => %{"content" => ""}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send-message", %{"message" => message_params}, socket) do
    case Message.insert(message_params) do
      {:ok, message} ->
        %{selected_chat_room: chat_room} = socket.assigns
        StridentWeb.Endpoint.broadcast_from(self(), chat_room, "message", message)

        socket
        |> assign(:message, Message.changeset(%Message{}))
        |> update_chats_with_new_message(message)

      _ ->
        put_flash(socket, :error, "Cannot send message")
    end
    |> assign_selected_chat()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("typing", _value, socket) do
    %{current_user: user, selected_chat_room: chat_room} = socket.assigns
    Presence.update_presence(self(), chat_room, user.id, %{typing: true})
    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_typing", %{"value" => value}, socket) do
    %{current_user: user, selected_chat_room: chat_room} = socket.assigns
    Presence.update_presence(self(), chat_room, user.id, %{typing: false})

    socket
    |> assign(:message, Message.changeset(%Message{}, %{content: value}))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info(%{event: "message", payload: message}, socket) do
    socket
    |> update_chats_with_new_message(message)
    |> then(&{:noreply, &1})
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    socket
    |> update(:chats, fn chats ->
      for {chat_room, chat_details} <- chats, reduce: %{} do
        chats ->
          %{participants: participants} = chat_details
          active_users = Presence.list_presences(chat_room)

          participants =
            for participant <- participants do
              build_chat_participant(participant.user, active_users, participant.type)
            end

          Map.put(chats, chat_room, %{chat_details | participants: participants})
      end
    end)
    |> assign_selected_chat()
    |> then(&{:noreply, &1})
  end

  @spec update_chats_with_new_message(Socket.t(), Message.t()) :: Socket.t()
  defp update_chats_with_new_message(socket, message) do
    socket
    |> update(:chats, fn chats ->
      for {chat_room, chat_details} <- chats, reduce: %{} do
        chats ->
          if chat_details.id == message.chat_id do
            messages = Enum.slide([message | chat_details.messages], 0, -1)
            Map.put(chats, chat_room, %{chat_details | messages: messages})
          else
            Map.put(chats, chat_room, chat_details)
          end
      end
    end)
    |> assign_selected_chat()
  end

  @spec do_mount(Socket.t(), map, map) :: {:ok, Socket.t(), Keyword.t()}
  defp do_mount(socket, params, session) do
    %{"tournament_id" => tournament_id} = Map.merge(params, session)

    %{
      current_user: current_user
    } = socket.assigns

    tournament = Tournaments.get_tournament_with_preloads_by([id: tournament_id], @preloads)

    chats =
      for stage <- tournament.stages,
          stage.status in [:scheduled, :in_progress],
          match <- stage.matches,
          not Matches.is_match_finished?(match) and !!match.chat and
            Enum.count(match.participants) > 1,
          reduce: %{} do
        chats ->
          chat_participants =
            tournament
            |> get_chat_participants(match)
            |> Enum.map(fn user ->
              if user.id == current_user.id do
                %{user | inactive?: false}
              else
                user
              end
            end)

          if current_user.id in Enum.map(chat_participants, & &1.id) do
            if connected?(socket) do
              Presence.track(
                self(),
                match.chat.room_name,
                current_user.id,
                default_user_presence_payload(current_user)
              )

              StridentWeb.Endpoint.subscribe(match.chat.room_name)
            end

            Map.put(chats, match.chat.room_name, %{
              id: match.chat.id,
              messages: match.chat.messages,
              participants: chat_participants,
              name: build_chat_name(match)
            })
          else
            chats
          end
      end

    socket
    |> assign(:is_connected, connected?(socket))
    |> assign(:tournament, tournament)
    |> assign(:chats, chats)
    |> assign(:message, Message.changeset(%Message{}))
    |> assign(:selected_chat_room, chats |> Map.keys() |> Enum.at(0))
    |> assign_selected_chat()
    |> then(&{:ok, &1, temporary_assigns: [messages: []]})
  end

  @spec assign_selected_chat(Socket.t()) :: Socket.t()
  defp assign_selected_chat(socket) do
    %{selected_chat_room: chat_room, chats: chats} = socket.assigns
    assign(socket, :selected_chat, Map.get(chats, chat_room))
  end

  @spec get_chat_participants(Tournament.t(), Match.t()) :: [map()]
  def get_chat_participants(tournament, match) do
    active_users = Presence.list_presences(match.chat.room_name)

    players =
      match.participants
      |> Enum.with_index()
      |> Enum.flat_map(fn {%{tournament_participant: tournament_participant}, team_index} ->
        Enum.map(
          tournament_participant.players,
          &build_chat_participant(&1.user, active_users, "player_#{team_index}")
        )
      end)

    [%{user: tournament.created_by} | tournament.management_personnel]
    |> Enum.map(&build_chat_participant(&1.user, active_users, "admin"))
    |> Kernel.++(players)
    |> Enum.group_by(& &1.user.id)
    |> Enum.map(fn
      {_x, [player]} -> player
      {_x, [player | _] = players} -> Enum.find(players, player, &(&1.type == "admin"))
    end)
  end

  defp build_chat_name(match) do
    match
    |> Map.get(:participants, [])
    |> Enum.sort_by(& &1.id)
    |> Enum.map_join(" VS ", &TournamentParticipants.participant_name(&1.tournament_participant))
  end

  defp build_chat_participant(user, active_users, type) do
    status = user.id not in Enum.map(active_users, & &1.user_id)

    typing =
      case Enum.find(active_users, &(&1.user_id == user.id)) do
        nil -> false
        struct -> Map.get(struct, :typing)
      end

    %{id: user.id, user: user, type: type, inactive?: status, typing: typing}
  end

  defp default_user_presence_payload(user) do
    %{user_id: user.id, typing: false}
  end

  # For now this is just idea how could we merge messages that
  # are same for user(like discord groups messages)
  # defp group_messages(message, messages \\ [])

  # defp group_messages([], messages), do: Enum.reverse(messages)

  # defp group_messages([message | tail], []) do
  #   messages = [%{user_id: message.user_id, messages: [message]}]
  #   group_messages(tail, messages)
  # end

  # defp group_messages([message | tail], [last_message | tail_messages] = messages) do
  #   messages =
  #     if last_message.user_id == message.user_id do
  #       [%{last_message | messages: [message | last_message.messages]} | tail_messages]
  #     else
  #       [%{user_id: message.user_id, messages: [message]} | messages]
  #     end

  #   group_messages(tail, messages)
  # end
end
