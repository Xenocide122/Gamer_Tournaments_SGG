defmodule StridentWeb.TournamentRegistrationLive.Components.RegistrationComponent do
  @moduledoc false
  use StridentWeb, :live_component

  import StridentWeb.TournamentRegistrationLive.Components.HelperComponent

  require Logger

  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.ChangesetUtils
  alias Strident.TournamentParticipants
  alias Strident.TournamentRegistrations
  alias Strident.Tournaments.TournamentInvitation
  alias Strident.Tournaments.TournamentParticipant
  alias StridentWeb.SegmentAnalyticsHelpers

  @input_multiplier 1_000_000

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{
      id: id,
      tournament: tournament,
      party_changeset: party_changeset,
      selected_users: selected_users,
      current_page: current_page,
      party_attrs: party_attrs,
      invitation: invitation
    } = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:id, id)
    |> assign(:tournament, tournament)
    |> assign(:party_changeset, party_changeset)
    |> assign(:selected_users, selected_users)
    |> assign(:party_attrs, party_attrs)
    |> assign(:slider_min, 0)
    |> assign(:default_split, Decimal.new("0.5"))
    |> assign(:zero_amount, Money.zero(tournament.buy_in_amount.currency))
    |> assign(:info_text, info_text(tournament))
    |> assign(:current_page, current_page)
    |> assign(:invitation, invitation)
    |> assign(:roster_details, build_roster_details(party_changeset, selected_users))
    |> assign_attrs()
    |> assign_changeset()
    |> assign_slider_max()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("create-tournament-participant", %{"tournament_participant" => params}, socket) do
    socket
    |> assign_changeset(params)
    |> create_tournament_participant()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("create-tournament-participant", _params, socket) do
    socket
    |> assign_changeset()
    |> create_tournament_participant()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change-participant-type", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change-tournament-participant", %{"tournament_participant" => params}, socket) do
    socket
    |> assign_changeset(params)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("change-tournament-participant", _params, socket) do
    {:noreply, socket}
  end

  defp assign_attrs(socket, attrs \\ %{})

  defp assign_attrs(%{assigns: %{tournament: %{allow_staking: true}}} = socket, attrs) do
    %{tournament: tournament} = socket.assigns

    attrs
    |> Map.put("tournament_id", tournament.id)
    |> build_participant_registration_fields(tournament)
    |> change_split()
    |> make_status_atom()
    |> then(&assign(socket, :attrs, &1))
  end

  defp assign_attrs(socket, attrs) do
    %{tournament: tournament} = socket.assigns

    attrs
    |> Map.put("tournament_id", tournament.id)
    |> Map.put("status", :confirmed)
    |> build_participant_registration_fields(tournament)
    |> then(&assign(socket, :attrs, &1))
  end

  defp make_status_atom(%{"status" => status} = attrs) when is_binary(status),
    do: Map.put(attrs, "status", String.to_existing_atom(status))

  defp make_status_atom(attrs), do: attrs

  defp assign_changeset(socket, attrs \\ %{}) do
    socket
    |> assign_attrs(attrs)
    |> then(fn socket ->
      attrs =
        case socket.assigns do
          %{attrs: attrs} when is_map(attrs) -> attrs
          _ -> %{}
        end

      changeset =
        TournamentParticipants.change_tournament_participant(%TournamentParticipant{}, attrs)

      assign(socket, :changeset, changeset)
    end)
  end

  defp build_participant_registration_fields(%{"registration_fields" => _} = attrs, _tournament),
    do: attrs

  defp build_participant_registration_fields(attrs, tournament) do
    for {registration_field, index} <- Enum.with_index(tournament.registration_fields),
        reduce: %{} do
      map ->
        Map.put(map, index, %{
          "name" => registration_field.field_name,
          "type" => registration_field.field_type
        })
    end
    |> then(&Map.put(attrs, "registration_fields", &1))
  end

  defp create_tournament_participant(%{assigns: %{changeset: %{valid?: false}}} = socket) do
    put_flash(socket, :info, "First input all the fields")
  end

  defp create_tournament_participant(%{assigns: %{invitation: %TournamentInvitation{}}} = socket) do
    %{
      current_user: current_user,
      party_attrs: party_attrs,
      changeset: changeset,
      attrs: attrs
    } = socket.assigns

    entry_fee_amount = Changeset.get_change(changeset, :initial_entry_fee_paid)

    register_participant_with_invitation(socket,
      user: current_user,
      participant_attrs: attrs,
      amount: entry_fee_amount,
      party_attrs: party_attrs
    )
  end

  defp create_tournament_participant(socket) do
    %{
      current_user: current_user,
      party_attrs: party_attrs,
      changeset: changeset,
      attrs: attrs
    } = socket.assigns

    entry_fee_amount = Changeset.get_change(changeset, :initial_entry_fee_paid)

    register_participant(socket,
      user: current_user,
      participant_attrs: attrs,
      amount: entry_fee_amount,
      party_attrs: party_attrs
    )
  end

  defp register_participant_with_invitation(socket, opts) do
    %{tournament: tournament, changeset: changeset, invitation: invitation} = socket.assigns

    case TournamentRegistrations.register_for_tournament_with_invitation(
           invitation,
           tournament,
           opts
         ) do
      {:ok, _participant} ->
        socket
        |> SegmentAnalyticsHelpers.track_segment_event("Registered For Tournament", %{
          tournament_id: tournament.id,
          game_title: tournament.game.title,
          stake_type: get_stake_type(changeset),
          amount: Keyword.get(opts, :amount)
        })
        |> put_flash(:info, "Registration successful!")
        |> redirect_to_tournament(tournament.slug)

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
        # redirect_to_tournament_with_error_message(socket, tournament.slug, error)
    end
  end

  defp register_participant(socket, opts) do
    %{assigns: %{changeset: changeset, tournament: tournament}} = socket

    case TournamentRegistrations.register_for_tournament(tournament, opts) do
      {:ok, _participant} ->
        socket
        |> SegmentAnalyticsHelpers.track_segment_event("Registered For Tournament", %{
          tournament_id: tournament.id,
          game_title: tournament.game.title,
          stake_type: get_stake_type(changeset),
          amount: Keyword.get(opts, :amount)
        })
        |> put_flash(:info, "Registration successful!")
        |> redirect_to_tournament(tournament.slug)

      {:error, %Changeset{} = changeset} ->
        error =
          changeset
          |> ChangesetUtils.error_codes()
          |> Map.values()
          |> Enum.map_join(", ", &inspect/1)

        error_message =
          "There was an issue with your registration. Please try again or contact the tournament organizer. #{error}"

        redirect_to_tournament_with_error_message(socket, tournament.slug, error_message)

      {:error, error} ->
        error_message =
          "There was an issue with your registration. Please try again or contact the tournament organizer. #{error}"

        redirect_to_tournament_with_error_message(socket, tournament.slug, error_message)
    end
  end

  defp get_stake_type(changeset) do
    case Changeset.get_change(changeset, :status) do
      :confirmed -> :full_entry_fee
      anything_else -> anything_else
    end
  end

  defp redirect_to_tournament_with_error_message(socket, tournament_slug, error_message) do
    socket
    |> put_flash(:error, error_message)
    |> redirect_to_tournament(tournament_slug)
  end

  defp redirect_to_tournament(socket, tournament_slug) do
    to = Routes.tournament_show_pretty_path(socket, :show, tournament_slug)
    push_navigate(socket, to: to)
  end

  defp info_text(tournament) do
    if Money.zero?(tournament.buy_in_amount) do
      "Spaces are first come, first serve."
    else
      "Spaces are first come, first serve. You are not guaranteed a place until the entry fee is paid in full."
    end
  end

  defp change_split(%{"split" => _split} = params) do
    params
    |> Map.get("split")
    |> slider_integer_to_split_decimal()
    |> then(&Map.put(params, "split", &1))
  end

  defp change_split(params), do: params

  @spec assign_slider_max(Socket.t()) :: Socket.t()
  defp assign_slider_max(socket) do
    assign(socket, :slider_max, 1 * @input_multiplier)
  end

  @spec slider_integer_to_split_decimal(integer) :: Decimal.t()
  defp slider_integer_to_split_decimal(int) do
    int
    |> Decimal.new()
    |> Decimal.div(@input_multiplier)
    |> Decimal.round(2, :floor)
  end

  defp get_party_name_from_changeset(changeset),
    do: Changeset.get_change(changeset, :name)

  defp get_logo_url_from_changeset(changeset),
    do: Changeset.get_change(changeset, :logo_url)

  defp build_roster_details(nil, _selected_users), do: []

  defp build_roster_details(changeset, selected_users) do
    invitations = Changeset.get_field(changeset, :party_invitations)
    members = Changeset.get_field(changeset, :party_members)

    for invitation <- invitations do
      user = Enum.find(selected_users, &(&1.id == invitation.user_id))

      user_details =
        if user do
          user
          |> Map.take([:display_name])
          |> Map.put(:avatar_url, Accounts.avatar_url(user))
        else
          nil
        end

      party_member =
        if user do
          Enum.find(members, &(&1.user_id == user.id))
        else
          nil
        end

      type =
        case party_member do
          %{type: :manager} -> "Team Manager"
          nil -> nil
          _ -> "Team Captain"
        end

      %{user: user_details, email: invitation.email, type: type}
    end
  end
end
