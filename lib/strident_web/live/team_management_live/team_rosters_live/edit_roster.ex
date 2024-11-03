defmodule StridentWeb.TeamRostersLive.EditRoster do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.Teams

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{roster: _, team: _, can_edit: _} = attrs, socket) do
    socket
    |> assign(attrs)
    |> sort_roster_members()
    |> assign_update_roster_members()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "add-roster-member",
        %{"player_roster_add" => %{"member" => member_id}},
        %{assigns: %{team: %{team_members: members}, roster: roster, can_edit: true}} = socket
      ) do
    case Teams.add_roster_member(%{team_member_id: member_id, team_roster_id: roster.id}) do
      {:ok, roster_member} ->
        team_member = Enum.find(members, &(&1.id == member_id))
        member = Map.put(%{roster_member | team_member: team_member}, :confirmed_delete, false)

        socket
        |> assign(:roster, %{roster | members: [member | roster.members]})
        |> sort_roster_members()
        |> then(&{:noreply, &1})

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not add member to roster. Please try again.")}
    end
  end

  @impl true
  def handle_event(
        "remove-variant",
        %{"remove" => member_id},
        %{assigns: %{roster: roster, can_edit: true}} = socket
      ) do
    member = Enum.find(roster.members, &(&1.id == member_id))

    case Teams.remove_roster_member(member) do
      {:ok, _} ->
        members =
          Enum.reduce(roster.members, [], fn
            %{id: id}, members when id == member_id ->
              members

            member, members ->
              [member | members]
          end)

        socket
        |> update(:roster, fn roster -> %{roster | members: members} end)
        |> sort_roster_members()
        |> then(&{:noreply, &1})

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Could not remove the member from the roster. Please try again."
         )}
    end
  end

  @impl true
  def handle_event(
        "cancel-remove",
        %{"remove" => member_id},
        %{assigns: %{roster: roster, can_edit: true}} = socket
      ) do
    members =
      Enum.reduce(roster.members, [], fn
        %{id: id} = member, members when id == member_id ->
          [%{member | confirmed_delete: false} | members]

        member, members ->
          [member | members]
      end)

    socket
    |> update(:roster, fn roster -> %{roster | members: members} end)
    |> sort_roster_members()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "roster-edit",
        %{"roster_player" => %{"confirm_delete" => "true", "id" => member_id}},
        %{assigns: %{roster: roster, can_edit: true}} = socket
      ) do
    members =
      Enum.reduce(roster.members, [], fn
        %{id: id} = member, members when id == member_id ->
          [%{member | confirmed_delete: true} | members]

        member, members ->
          [member | members]
      end)

    socket
    |> update(:roster, fn roster -> %{roster | members: members} end)
    |> sort_roster_members()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "roster-edit",
        %{"roster_player" => %{"id" => member_id} = params},
        %{assigns: %{roster: roster, can_edit: true}} = socket
      ) do
    member = Enum.find(roster.members, &(&1.id == member_id))

    case Teams.update_roster_member(member, params) do
      {:ok, %{id: member_id} = updated_roster_member} ->
        members =
          Enum.reduce(roster.members, [], fn
            %{id: id}, members when id == member_id ->
              [updated_roster_member | members]

            member, members ->
              [member | members]
          end)

        socket
        |> update(:roster, fn roster -> %{roster | members: members} end)
        |> sort_roster_members()
        |> then(&{:noreply, &1})

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not modify roster member. Please try again.")}
    end
  end

  defp sort_roster_members(socket) do
    update(socket, :roster, fn %{members: members} = roster ->
      %{roster | members: Enum.sort_by(members, &{&1.inserted_at, &1.id})}
    end)
  end

  defp sort_captain_last(roster_members) do
    roster_members
    |> Enum.split_with(&(&1.type == :captain))
    |> then(&Enum.concat(elem(&1, 1), elem(&1, 0)))
  end

  defp assign_update_roster_members(socket) do
    update(socket, :roster, fn roster ->
      %{roster | members: Enum.map(roster.members, &Map.put(&1, :confirmed_delete, false))}
    end)
  end
end
