defmodule StridentWeb.PartyManagementLive.Components.Party do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.HTML.Form
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.Parties.PartyInvitation
  alias Strident.Parties.PartyMember

  attr(:player, :map, required: true)

  def username(%{player: %PartyMember{user: %{slug: nil}}} = assigns) do
    ~H"""
    Deleted User
    """
  end

  def username(%{player: %PartyMember{user: %{}}} = assigns) do
    ~H"""
    <%= @player.user.display_name %>
    """
  end

  def username(%{player: %PartyInvitation{status: :pending}} = assigns) do
    ~H"""
    <%= maybe_get_display_name(@player) %>
    """
  end

  def username(assigns) do
    ~H"""
    <p class="text-secondary"><%= maybe_get_display_name(@player) %></p>
    """
  end

  attr(:player, :map, required: true)

  def email(%{player: %PartyInvitation{status: :pending, user_id: nil, email: email}}) do
    assigns = %{email: email}
    ~H"<%= @email %>"
  end

  def email(assigns) do
    ~H"<%= nil %>"
  end

  attr(:player, :map, required: true)

  def invitation_status(%{player: %PartyMember{}} = assigns) do
    ~H"""
    Accepted
    """
  end

  def invitation_status(assigns) do
    ~H"""
    <p class={if(@player.status == :pending, do: "text-grey-light", else: "text-secondary")}>
      <%= humanize(@player.status) %>
    </p>
    """
  end

  attr(:player, :map, required: true)
  attr(:tournament, :map, required: true)
  attr(:current_user, :map, required: true)
  attr(:state, :atom, required: true)

  def manage_player(%{player: %PartyMember{}} = assigns) do
    ~H"""
    <.type_switch
      id={"switch-manager-#{@player.id}"}
      party_member={@player}
      label="Manager"
      type={:manager}
      state={@state}
    />
    <.type_switch
      id={"switch-captain-#{@player.id}"}
      party_member={@player}
      label="Captain"
      type={:captain}
      state={@state}
    />
    <.player_subsitute party_member={@player} state={@state} />

    <%= if @tournament.status in [:scheduled, :registrations_open] do %>
      <button
        class="btn btn--secondary-ghost btn--sm"
        phx-click="drop-party-member"
        phx-value-id={@player.id}
        phx-value-player-type="party-member"
      >
        Drop
      </button>
    <% end %>
    """
  end

  def manage_player(%{player: %PartyInvitation{status: :pending}, state: :enabled} = assigns) do
    ~H"""
    <div class="flex justify-between">
      <button
        class="mr-2 btn btn--primary-ghost btn--sm"
        phx-click="send-invitation"
        phx-value-id={@player.id}
      >
        Send Invitation
      </button>

      <button
        class="mr-2 btn btn--secondary-ghost btn--sm"
        phx-click="drop-party-member"
        phx-value-id={@player.id}
        phx-value-player-type="party-invitation"
      >
        Drop
      </button>
    </div>
    """
  end

  def manage_player(%{player: %PartyInvitation{status: :dropped}, state: :enabled} = assigns) do
    ~H"""
    <div class="flex justify-between">
      <button
        class="mr-2 btn btn--primary-ghost btn--sm"
        phx-click="re-invite-party-member"
        phx-value-id={@player.id}
        phx-value-player-type="party-invitation"
      >
        Re-Invite
      </button>
    </div>
    """
  end

  def manage_player(assigns) do
    ~H"""
    <div class="text-grey-light">
      Invitation not accepted
    </div>
    """
  end

  def type_switch(assigns) do
    ~H"""
    <div class="flex">
      <div class=""><%= @label %></div>
      <button
        id={@id}
        phx-click="update-type"
        phx-value-change={if @party_member.type == @type, do: @party_member.type, else: @type}
        phx-value-id={@party_member.id}
        type="button"
        class={
          "#{if @party_member.type == @type, do: "left-0", else: "left-1"} mx-4 group relative inline-flex h-5 w-6 flex-shrink-0 cursor-pointer items-center justify-center rounded-full focus:outline-none "
        }
        role="switch"
        aria-checked="false"
        disabled={if @state == :disabled, do: "true"}
      >
        <!-- Enabled: "bg-primary", Not Enabled: "bg-gray-200" -->
        <span
          aria-hidden="true"
          class={
            "#{if @party_member.type == @type, do: "bg-primary w-4", else: "bg-gray-200 w-5"} pointer-events-none absolute mx-auto h-2 rounded-full transition-colors duration-200 ease-in-out"
          }
        >
        </span>
        <!-- Enabled: "translate-x-5", Not Enabled: "translate-x-0" -->
        <span
          aria-hidden="true"
          class={
            "#{if @party_member.type == @type, do: "translate-x-4", else: "translate-x-0 "}  pointer-events-none absolute left-0 inline-block h-3 w-3 transform rounded-full border border-gray-200 bg-white shadow ring-0 transition-transform duration-200 ease-in-out"
          }
        >
        </span>
      </button>
    </div>
    """
  end

  def player_subsitute(assigns) do
    ~H"""
    <div class="flex">
      <%= case @party_member.type do %>
        <% :manager -> %>
          <div class="flex items-center flex-none mr-3 space-x-2 cursor-pointer">
            <div class="radio w-[14px]">
              <div class="radio--border" />
              <div class="radio--inner" />
            </div>
            <div class="flex-none text-sm text-muted">
              Starter
            </div>
          </div>
          <div class="flex items-center flex-none mr-3 space-x-2 cursor-pointer">
            <div class="radio w-[14px]">
              <div class="radio--border" />
              <div class="radio--inner" />
            </div>
            <div class="flex-none text-sm text-muted">
              Substitute
            </div>
          </div>
        <% _ -> %>
          <%= if @state == :disabled do %>
            <div class="flex items-center flex-none mr-3 space-x-2 cursor-pointer">
              <div class="radio w-[14px]" on={@party_member.substitute == false}>
                <div class="radio--border" />
                <div class="radio--inner" />
              </div>
              <div class="flex-none text-sm">
                Starter
              </div>
            </div>
            <div class="flex items-center flex-none mr-3 space-x-2 cursor-pointer">
              <div class="radio w-[14px]" on={@party_member.substitute}>
                <div class="radio--border" />
                <div class="radio--inner" />
              </div>
              <div class="flex-none text-sm">
                Substitute
              </div>
            </div>
          <% else %>
            <div
              id={"pick-starter-#{@party_member.id}"}
              class="flex items-center flex-none mr-3 space-x-2 cursor-pointer"
              phx-click="update-substitute"
              phx-value-change="false"
              phx-value-id={@party_member.id}
            >
              <div class="radio w-[14px]" on={@party_member.substitute == false}>
                <div class="radio--border" />
                <div class="radio--inner" />
              </div>
              <div class="flex-none text-sm">
                Starter
              </div>
            </div>
            <div
              id={"pick-substitute-#{@party_member.id}"}
              class="flex items-center flex-none mr-3 space-x-2 cursor-pointer"
              phx-click="update-substitute"
              phx-value-change="true"
              phx-value-id={@party_member.id}
            >
              <div class="radio w-[14px]" on={@party_member.substitute}>
                <div class="radio--border" />
                <div class="radio--inner" />
              </div>
              <div class="flex-none text-sm">
                Substitute
              </div>
            </div>
          <% end %>
      <% end %>
    </div>
    """
  end

  def amount(assigns) do
    ~H"""
    <div class="w-full">
      <div class="flex items-center justify-end space-x-4">
        <div class="relative w-full rounded shadow-sm">
          <div class="absolute inset-y-0 left-0 flex items-center pl-5 pointer-events-none">
            <div class="text-xl text-gray-400">$</div>
          </div>
          <.form
            :let={f}
            for={to_form(%{}, as: :split)}
            phx-change="set-amount"
            phx-value-pm-id={@id}
            phx-target={@myself}
          >
            <.live_component
              module={StridentWeb.Common.MoneyInput}
              f={f}
              hidden={false}
              min={0}
              max={1_000_000}
              field={@id}
              value={@amount}
              id={@id}
            />
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp maybe_get_display_name(%{user_id: nil, email: email} = _party_invitation) do
    case Accounts.get_user_by_email(email) do
      nil -> "Unregistered"
      %User{slug: nil} -> "Deleted User"
      user -> user.display_name
    end
  end

  defp maybe_get_display_name(%{user_id: user_id} = _party_invitation) do
    case Accounts.get_user(user_id) do
      nil -> "Unregistered"
      %User{slug: nil} -> "Deleted User"
      user -> user.display_name
    end
  end
end
