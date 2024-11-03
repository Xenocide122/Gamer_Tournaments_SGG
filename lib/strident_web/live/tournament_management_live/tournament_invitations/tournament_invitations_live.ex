defmodule StridentWeb.TournamentInvitationsLive do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Accounts
  alias Strident.Parties
  alias Strident.TournamentRegistrations
  alias Strident.Tournaments
  alias StridentWeb.TournamentManagment.Setup
  alias Phoenix.LiveView.JS

  on_mount({StridentWeb.InitAssigns, :default})
  on_mount(Setup)

  @impl true
  def render(assigns) do
    ~H"""
    <.container id={"tournament-invitations-#{@tournament.id}"}>
      <:side_menu>
        <.live_component
          id={"side-menu-#{@tournament.id}"}
          module={StridentWeb.TournamentManagement.Components.SideMenu}
          can_manage_tournament={@can_manage_tournament}
          tournament={@tournament}
          number_of_participants={
            Enum.count(@tournament.participants, &(&1.status in Tournaments.on_track_statuses()))
          }
          current_user={@current_user}
          live_action={@team_site}
          timezone={@timezone}
          locale={@locale}
        />
      </:side_menu>

      <div class="px-4 md:px-32">
        <section :if={!!@tournament_invitation} class="py-8">
          <h3 class="pb-4 text-6xl leading-none tracking-normal font-display">
            Tournament Invitation
          </h3>
          <div class="flex gap-4">
            <.button
              id={"accept-tournament-invite-button-#{@tournament_invitation.id}"}
              button_type={:primary}
              phx-click={
                JS.navigate(
                  "/tournament/#{@tournament_slug}/participant/registration/#{@tournament_invitation.id}"
                )
              }
            >
              Accept Tournament Invite
            </.button>

            <.button
              id={"reject-roster-invite-button-#{@tournament_invitation.id}"}
              button_type={:secondary}
              phx-click="reject-tournament-invite"
            >
              <.svg icon={:x} width="40" height="40" class=" fill-secondary-dark" />
            </.button>
          </div>
        </section>

        <section :if={Enum.any?(@roster_invites)}>
          <h2 class="text-6xl leading-none tracking-normal font-display">
            Roster Invitations
          </h2>

          <div :for={invite <- @roster_invites} class="my-8">
            <.card>
              <div class="flex justify-between">
                <h3><%= invite.party.name %></h3>
                <div class="">
                  <div class="flex gap-2 mt-4 md:mt-0">
                    <.button
                      :if={invite.status == :pending}
                      id={"accept-roster-invite-button-#{invite.id}"}
                      button_type={:primary}
                      phx-value-invite-id={invite.id}
                      phx-click="accept-roster-invite"
                    >
                      Accept Invite
                    </.button>

                    <.button
                      :if={invite.status == :pending}
                      id={"reject-roster-invite-button-#{invite.id}"}
                      button_type={:secondary}
                      phx-value-invite-id={invite.id}
                      phx-click="reject-roster-invite"
                    >
                      Reject Invite
                    </.button>
                  </div>
                </div>
              </div>
              <div class="flex justify-between">
                <h4>Roster:</h4>
              </div>
              <div class="flex items-center justify-between mt-4 md:flex">
                <div class="grid grid-cols-3 gap-4">
                  <.roster_member
                    :for={party_member <- invite.party.party_members}
                    id={party_member.id}
                    image={Accounts.avatar_url(party_member.user)}
                    name={Accounts.user_display_name(party_member.user)}
                  >
                    <p :if={party_member.type == :manager} class="text-sm text-grey-light">
                      Team Manager
                    </p>
                    <p :if={party_member.type == :player} class="text-sm text-grey-light">Starter</p>
                    <p :if={party_member.type == :substitute} class="text-sm text-grey-light">
                      Substitute
                    </p>
                    <p :if={party_member.type == :captain} class="text-sm text-grey-light">
                      Team Captain
                    </p>
                    <p :if={party_member.type == :coach} class="text-sm text-grey-light">
                      Team Coach
                    </p>
                  </.roster_member>
                </div>
              </div>
            </.card>
          </div>
        </section>
      </div>
    </.container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    %{tournament: tournament, current_user: current_user} = socket.assigns
    invitations = Strident.Rosters.get_users_roster_invites(tournament.id, current_user)

    tournament_invitation =
      Tournaments.get_users_tournament_pending_invitation(current_user, tournament)

    socket
    |> assign(:team_site, :invites)
    |> assign(:roster_invites, invitations)
    |> assign(:tournament_invitation, tournament_invitation)
    |> assign(:tournament_slug, tournament.slug)
    |> assign(
      :can_manage_tournament,
      Tournaments.can_manage_tournament?(current_user, tournament)
    )
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("accept-roster-invite", %{"invite-id" => invite_id}, socket) do
    socket
    |> push_navigate(
      to:
        Routes.live_path(
          socket,
          StridentWeb.TournamentRegistrationLive.Index,
          socket.assigns.tournament.slug,
          party_invitation: invite_id
        )
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reject-roster-invite", %{"invite-id" => invite_id}, socket) do
    case invite_id |> Parties.get_party_invitation!() |> Parties.reject_party_invitation() do
      {:ok, _invitation} ->
        socket
        |> update(
          :roster_invites,
          &update_roster_invites_with_new_status(&1, invite_id, :rejected)
        )
        |> put_flash(:info, "Invitation rejected")

      {:error, changeset} ->
        put_string_or_changeset_error_in_flash(socket, changeset)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("reject-tournament-invite", _params, socket) do
    %{tournament_invitation: invitation, tournament_slug: tournament_slug} = socket.assigns

    case TournamentRegistrations.reject_tournament_invitation(invitation) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "You have rejected tournament invitation.")
        |> push_navigate(to: ~p"/t/#{tournament_slug}")

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
    |> then(&{:noreply, &1})
  end

  attr(:id, :string, required: true)
  attr(:image, :string, required: true)
  attr(:name, :string, required: true)
  slot(:inner_block, required: true)

  def roster_member(assigns) do
    ~H"""
    <div id={"roster-member-#{@id}"}>
      <.slim_card colored={true} inner_class="md:w-64 md:h-24">
        <div class="items-center justify-start md:flex">
          <.image
            id={"created-by-avatar-#{@id}"}
            image_url={@image}
            alt="logo"
            class="rounded-full"
            width={50}
            height={50}
          />

          <div class="flex-1 min-w-0 pl-2">
            <p class="text-left truncate md:text-center lg:text-left text-primary">
              <%= @name %>
            </p>

            <p class="text-sm text-center truncate lg:text-left text-grey-light">
              <%= render_slot(@inner_block) %>
            </p>
          </div>
        </div>
      </.slim_card>
    </div>
    """
  end

  attr(:status, :atom, required: true)

  defp invitation_status(assigns) do
    default_class = "capitalize font-display text-3xl"

    status_dependant_class =
      case assigns.status do
        :pending -> "text-grey-light"
        :accepted -> "text-primary"
        :rejected -> "text-secondary"
      end

    default_assigns = %{class: [status_dependant_class, default_class]}
    assigns = Map.merge(default_assigns, assigns)

    ~H"""
    <div class={@class}>
      <%= @status %>
    </div>
    """
  end

  defp update_roster_invites_with_new_status(roster_invites, invite_id, new_status) do
    Enum.map(
      roster_invites,
      fn roster_invite ->
        if roster_invite.id == invite_id,
          do: %{roster_invite | status: new_status},
          else: roster_invite
      end
    )
  end
end
