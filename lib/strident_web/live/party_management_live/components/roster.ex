defmodule StridentWeb.PartyManagementLive.Components.Roster do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Parties.PartyInvitation
  alias Strident.Parties.PartyMember
  import StridentWeb.PartyManagementLive.Components.Party

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{party: party, tournament: tournament} = assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign(party: party)
    |> assign(tournament: tournament)
    |> then(&{:ok, &1})
  end

  defp row_id(%PartyMember{id: id}), do: "roster-member-#{id}"
  defp row_id(%PartyInvitation{id: id}), do: "roster-invitation-#{id}"
end
