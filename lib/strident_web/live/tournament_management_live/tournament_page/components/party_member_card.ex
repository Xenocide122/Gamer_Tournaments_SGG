defmodule StridentWeb.TournamentManagementLive.TournamentPage.Components.PartyMemberCard do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts
  alias Strident.Accounts.User
  alias Strident.Parties.PartyInvitation
  alias Strident.Parties.PartyMember

  @impl true
  def render(%{item: %PartyMember{user: %User{slug: nil}}} = assigns) do
    ~H"""
    <div class="hidden"></div>
    """
  end

  def render(%{item: %PartyMember{}} = assigns) do
    ~H"""
    <div>
      <.link
        navigate={Routes.user_show_path(@socket, :show, @item.user.slug)}
        class="hover:no-underline"
      >
        <.build_card
          id={@id}
          image={Accounts.avatar_url(@item.user)}
          display_text={Accounts.user_display_name(@item.user)}
          display_status={set_member_status(%{type: @item.type, show_real_status: @show_real_status})}
        />
      </.link>
    </div>
    """
  end

  @impl true
  def render(%{item: %PartyInvitation{}} = assigns) do
    ~H"""
    <div>
      <.build_card
        id={@id}
        image={Accounts.avatar_url(nil)}
        display_text="invited via email"
        display_status={"Invite #{humanize(@item.status)}"}
        opacity={75}
      />
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{id: id, item: item} = assigns

    socket
    |> assign(:id, id)
    |> assign(:item, item)
    |> assign(:show_real_status, Map.get(assigns, :show_real_status, false))
    |> then(&{:ok, &1})
  end

  defp build_card(assigns) do
    assigns = assign_new(assigns, :opacity, fn -> 100 end)

    ~H"""
    <div id={@id}>
      <.slim_card class={"opacity-#{@opacity}"} colored={true} inner_class="w-full md:w-64">
        <div class="flex items-center justify-start">
          <img
            src={@image}
            alt="Player"
            width="50"
            height="50"
            class={"object-scale-down rounded-full opacity-#{@opacity}"}
          />

          <div class="flex-1 min-w-0 pl-2">
            <p class={
              "text-left md:text-center truncate lg:text-left text-primary opacity-#{@opacity}"
            }>
              <%= @display_text %>
            </p>
            <p class={"text-sm text-center truncate lg:text-left text-grey-light opacity-#{@opacity}"}>
              <%= @display_status %>
            </p>
          </div>
        </div>
      </.slim_card>
    </div>
    """
  end

  defp set_member_status(%{type: :manager} = assigns) do
    ~H"""
    <p class="text-sm text-grey-light">Team Manager</p>
    """
  end

  defp set_member_status(%{type: :player, show_real_status: true} = assigns) do
    ~H"""
    <p class="text-sm text-grey-light">Starter</p>
    """
  end

  defp set_member_status(%{type: :substitute, show_real_status: true} = assigns) do
    ~H"""
    <p class="text-sm text-grey-light">Substitute</p>
    """
  end

  defp set_member_status(%{type: :captain, show_real_status: true} = assigns) do
    ~H"""
    <p class="text-sm text-grey-light">Team Captain</p>
    """
  end

  defp set_member_status(%{type: :coach, show_real_status: true} = assigns) do
    ~H"""
    <p class="text-sm text-grey-light">Team Coach</p>
    """
  end

  defp set_member_status(assigns) do
    ~H"""
    <div class="flex items-center">
      <p class="text-sm text-grey-light">Invite Accepted</p>
      <.svg icon={:circle_check} width="20" height="20" class="fill-primary" />
    </div>
    """
  end
end
