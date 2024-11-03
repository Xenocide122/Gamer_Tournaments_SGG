defmodule StridentWeb.TournamentParticipantLive.Components.Widgets do
  @moduledoc false
  use Phoenix.Component
  use Phoenix.HTML
  use Phoenix.VerifiedRoutes, endpoint: StridentWeb.Endpoint, router: StridentWeb.Router

  import StridentWeb.Common.SvgUtils
  import StridentWeb.DeadViews.Button
  import StridentWeb.Components.Modal
  import StridentWeb.Components.Form
  import StridentWeb.CoreComponents
  import StridentWeb.Components.Containers

  alias Strident.Accounts
  alias Strident.TournamentParticipants
  alias Strident.Tournaments
  alias Phoenix.LiveView.JS

  attr(:phx_target, :any, required: true)
  attr(:valid_invitation_email, :boolean, default: false)
  attr(:invitation_email_error, :string, default: "")

  def send_invitation_form(assigns) do
    ~H"""
    <form
      id="send-invitation-form"
      phx-change="validate-invitation-email"
      phx-submit="send-invite"
      phx-target={@phx_target}
      class="py-2"
    >
      <div class="flex items-center justify-start w-fit">
        <input
          name="email"
          type="email"
          class="w-full mr-2 form-input"
          phx-debounce="500"
          autocomplete="off"
          placeholder="Enter email"
        />

        <.button
          id="send-tournament-invitation"
          type="submit"
          button_type={:primary}
          class="w-full"
          disabled={!@valid_invitation_email}
        >
          Send Invitation
        </.button>
      </div>
      <p :if={@invitation_email_error} class="text-sm text-secondary-dark">
        <%= @invitation_email_error %>
      </p>

      <p class="mt-2 text-xs text-grey-light">
        Enter email address and we will send them invitation to join the tournament.
      </p>
    </form>
    """
  end

  attr(:tournament_type, :atom, required: true)
  attr(:status_filters, :list, required: true)
  attr(:search_term, :string, required: true)
  attr(:can_manage_tournament, :boolean, required: true)
  attr(:form, :any, default: to_form(%{}, as: :participant_filters))
  attr(:phx_target, :any, required: true)

  def participants_filters(assigns) do
    ~H"""
    <div class="py-2 md:py-4 flex flex-col justify-center w-128 gap-2 text-sm ">
      <.form
        :let={f}
        for={@form}
        id="filter-participants-form"
        phx-change="participants-filters-change"
        phx-target={@phx_target}
      >
        <div class="relative flex items-center mb-4">
          <.form_text_input
            id="search-participant-input"
            form={f}
            field={:search_term}
            value={@search_term}
            phx-debounce={300}
            class=" px-2 border-1 border-primary rounded-md bg-blackish"
            placeholder="Search participants"
          />
          <.svg icon={:search} width="24" height="24" class="absolute right-1 fill-primary" />
        </div>

        <div class="flex justify-end items-center gap-2">
          <div
            :if={@can_manage_tournament and @tournament_type == :invite_only}
            class="flex items-center"
          >
            <div class={[
              "relative flex items-center justify-center flex-shrink-0 w-5 h-5 mr-2 bg-transparent border-2 border-primary"
            ]}>
              <%= checkbox(f, :only_invited,
                class: "opacity-0 absolute text-primary",
                checked: @status_filters == [:invited]
              ) %>

              <.svg
                icon={:solid_check}
                width="16"
                height="16"
                class={[
                  "transition pointer-events-none fill-primary",
                  if(@status_filters != [:invited], do: "hidden")
                ]}
              />
            </div>
            <div class={["hidden md:block", if(false, do: "text-primary")]}>Invited Participants</div>
            <div class={["md:hidden", if(false, do: "text-primary")]}>Invited</div>
          </div>

          <div :if={@can_manage_tournament} class="flex items-center justify-start md:justify-center">
            <div class={[
              "relative flex items-center justify-center flex-shrink-0 w-5 h-5 mr-2 bg-transparent border-2 border-primary"
            ]}>
              <%= checkbox(f, :only_dropped,
                class: "opacity-0 absolute",
                checked: @status_filters == [:dropped]
              ) %>

              <.svg
                icon={:solid_check}
                width="16"
                height="16"
                class={[
                  "transition pointer-events-none fill-primary",
                  if(@status_filters != [:dropped], do: "hidden")
                ]}
              />
            </div>
            <div class={["hidden md:block text-primary"]}>Dropped Participants</div>
            <div class={["md:hidden text-primary"]}>Dropped</div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:status, :atom, required: true)
  attr(:rank, :integer, required: true)
  attr(:email, :string, required: true)
  attr(:invitation_status, :atom, required: true)
  attr(:tournament_type, :boolean, required: true)
  attr(:tournament_status, :boolean, required: true)
  attr(:free_tournament, :boolean, required: true)
  attr(:invitation_token, :string, default: "")
  attr(:registration_fields, :list, default: [])
  attr(:can_manage_tournament, :boolean, required: true)
  attr(:roster_members, :list, default: [])
  attr(:roster_invitations, :list, default: [])
  attr(:ranks_frequency, :any, default: %{})
  attr(:prize_money, :any, default: nil)

  def participant_card(assigns) do
    label_text =
      TournamentParticipants.status_label(
        assigns.status,
        assigns.rank,
        assigns.tournament_status,
        assigns.invitation_status,
        assigns.ranks_frequency
      )

    label_class =
      case label_text do
        "Crowdfunding Entry Fee" -> "text-sm text-primary"
        "Participant Invited" -> "text-sm text-left text-grey-light"
        "" -> ""
        "Participant Entered" -> "text-sm text-grey-light"
        "Playing Now" -> "text-sm text-grey-light"
        "1st" -> "text-xl font-bold text-left font-display first-place-rank__gradient"
        "2nd" -> "text-xl font-bold text-left font-display text-primary"
        "3rd" -> "text-xl font-bold text-left font-display text-primary"
        "TOP " <> _ -> "text-xl font-bold text-left font-display text-primary"
        "Unranked" -> "text-xl font-bold text-left uppercase font-display text-grey-light"
        _ -> "text-xl font-bold text-left font-display text-grey-light"
      end

    new_assigns = %{label_text: label_text, label_class: label_class}
    assigns = assign(assigns, new_assigns)

    ~H"""
    <div
      id={"tournament-participant-#{@id}"}
      class={["pb-2 md:pb-8", if(@status == :dropped, do: "opacity-50")]}
    >
      <div class="py-2 md:flex md:items-center md:justify-between md:py-4">
        <h3 class={
          if(
            (@tournament_type == :invite_only and @status == :invited and
               @invitation_status == :pending) or @status == :empty,
            do: "text-grey-light"
          )
        }>
          <%= @name %>
        </h3>

        <p :if={!!@label_text && @label_class} class={@label_class}><%= @label_text %></p>
        <div
          :if={!!@prize_money and Money.positive?(@prize_money)}
          class="flex flex-col items-center justify-center"
        >
          <div class="text-xl font-display text-primary">
            Won <%= @prize_money %>
          </div>
        </div>

        <div :if={@can_manage_tournament} class="flex">
          <.button
            :if={
              @can_manage_tournament and
                @tournament_type == :invite_only and @status == :invited and
                @invitation_status == :pending
            }
            id={"send-invitation-button-#{@id}"}
            button_type={:primary_ghost}
            class="mr-2"
            phx-click="send-reminder"
            phx-value-token={@invitation_token}
          >
            Send Reminder
          </.button>

          <.button
            :if={
              @can_manage_tournament and @status not in Tournaments.off_track_participant_statuses()
            }
            id={"open-modal-drop-participant-button-#{@id}"}
            button_type={:secondary_ghost}
            phx-click={show_modal("drop-participant-modal-invite-only-#{@id}")}
          >
            Drop
          </.button>
        </div>
      </div>

      <button
        id={"show-roster-#{@id}"}
        class="hidden text-primary hover:underline"
        phx-click={
          JS.toggle(to: "#roster-#{@id}")
          |> JS.toggle(to: "#show-roster-#{@id}")
          |> JS.toggle(to: "#hide-roster-#{@id}")
        }
      >
        Show Roster
      </button>

      <button
        id={"hide-roster-#{@id}"}
        class=" text-grey-light hover:underline"
        phx-click={
          JS.toggle(to: "#roster-#{@id}")
          |> JS.toggle(to: "#show-roster-#{@id}")
          |> JS.toggle(to: "#hide-roster-#{@id}")
        }
      >
        Hide Roster
      </button>

      <div id={"roster-#{@id}"} class="grid grid-cols-2 gap-4 pt-2 pb-8 lg:grid-cols-3 xl:grid-cols-4">
        <.player_card
          :for={%{user: %{slug: slug}} = member when is_binary(slug) <- @roster_members}
          id={"roster-member-#{member.id}"}
          name={Accounts.user_display_name(member.user)}
          image={Accounts.avatar_url(member.user)}
          navigate={~p"/user/#{member.user.slug}"}
        />

        <.player_card
          :for={invitation <- @roster_invitations}
          id={"roster-invitation-#{invitation.id}"}
          name="TBD"
          image={Accounts.return_default_avatar()}
        />
      </div>

      <div :if={@can_manage_tournament} class="p-px mt-4">
        <.card colored={true}>
          <div class="px-8 py-4 border-b border-opacity-50 border-grey-light">
            <h4>Participant Information</h4>
          </div>

          <div>
            <dl>
              <div
                id={"participant-email-#{@id}"}
                class="px-8 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6"
              >
                <dt class="font-medium text-grey-light">Email</dt>
                <dd :if={@can_manage_tournament} class="mt-1 sm:col-span-2 sm:mt-0"><%= @email %></dd>
              </div>

              <div
                :for={field <- @registration_fields}
                id={"registration-field-#{field.id}"}
                class="px-8 py-4 border-t border-opacity-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 border-grey-light"
              >
                <dt :if={@can_manage_tournament} class="font-medium text-grey-light">
                  <%= humanize(field.name) %>
                </dt>
                <dd :if={@can_manage_tournament} class="mt-1 sm:col-span-2 sm:mt-0">
                  <%= field.value %>
                </dd>
              </div>
            </dl>
          </div>
        </.card>
      </div>

      <div class="h-0">
        <.live_component
          id={"drop-participant-modal-invite-only-#{@id}"}
          module={StridentWeb.TournamentParticipantsLive.Components.DropParticipantModal}
          participant_id={@id}
          participant_name={@name}
          participant_status={@status}
          free_tournament={@free_tournament}
          can_manage_tournament={@can_manage_tournament}
        />
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:image, :string, required: true)
  attr(:name, :string, required: true)
  attr(:set_opacity, :boolean, default: false)
  slot(:inner_block, required: true)

  def roster_member(assigns) do
    ~H"""
    <.player_card id={@id} name={@name} image={@image} />
    """
  end

  attr(:class, :any, default: "")
  attr(:inner_class, :any, default: "")
  attr(:rest, :global, include: [])
  slot(:inner_block, required: true)

  def color_card(assigns) do
    ~H"""
    <div class={["p-px bg-gradient-to-l from-[#03d5fb] to-[#ff6802]", @class]} {@rest}>
      <div class={[@inner_class, "bg-blackish"]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
