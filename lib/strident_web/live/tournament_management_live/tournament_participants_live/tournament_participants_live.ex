defmodule StridentWeb.TournamentParticipantsLive do
  @moduledoc false
  use StridentWeb, :live_component
  import StridentWeb.TournamentParticipantLive.Components.Widgets

  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.Emails
  alias Strident.TournamentParticipants
  alias Strident.TournamentRegistrations
  alias Strident.Tournaments
  alias Phoenix.LiveView.JS

  @participant_preloads [
    :registration_fields,
    :active_invitation,
    :tournament_invitations,
    players: :user,
    team: [team_members: :user],
    party: [party_members: :user, party_invitations: []]
  ]

  @participants_per_page 25
  @empty_search_term ""

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  def handle_params(_params, _session, socket) do
    socket
  end

  @impl true
  def update(assigns, socket) do
    %{
      tournament: tournament,
      number_of_participants: number_of_participants,
      ranks_frequency: ranks_frequency,
      can_manage_tournament: can_manage_tournament
    } = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:tournament, tournament)
    |> assign(:number_of_participants, number_of_participants)
    |> assign(:ranks_frequency, ranks_frequency)
    |> assign(:can_manage_tournament, can_manage_tournament)
    |> assign(:pagination, page: 1, page_size: @participants_per_page)
    |> assign(:filtered_statuses, default_filtered_statuses())
    |> assign(:search_term, @empty_search_term)
    |> refetch_paginated_participants()
    |> assign(:validation_invite_email, "")
    |> assign(:form, to_form(%{}, as: :qa_hacks))
    |> then(&{:ok, &1})
  end

  defp refetch_paginated_participants(socket) do
    %{
      tournament: tournament,
      pagination: pagination,
      filtered_statuses: filtered_statuses,
      search_term: search_term
    } = socket.assigns

    opts = [
      pagination: pagination,
      preloads: @participant_preloads,
      filter_statuses: filtered_statuses,
      search_term: search_term,
      order_by: [{:asc_nulls_last, :rank}, {:asc_nulls_last, :inferred_name}]
    ]

    paginated_participants =
      TournamentParticipants.paginate_tournament_participants(tournament.id, opts)

    assign(socket, :paginated_participants, paginated_participants)
  end

  @impl true
  def handle_event("click-participant-page-number", params, socket) do
    %{"page-number" => page_number_string} = params
    page_number = String.to_integer(page_number_string)
    %{pagination: current_pagination} = socket.assigns
    current_page_number = Keyword.get(current_pagination, :page)

    socket
    |> then(fn socket ->
      if page_number == current_page_number do
        socket
      else
        new_pagination = Keyword.merge(current_pagination, page: page_number)

        socket
        |> assign(:pagination, new_pagination)
        |> refetch_paginated_participants()
      end
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("participants-filters-change", params, socket) do
    %{"participant_filters" => participant_filters} = params
    only_dropped = Map.get(participant_filters, "only_dropped") == "true"
    only_invited = Map.get(participant_filters, "only_invited") == "true"
    search_term = Map.get(participant_filters, "search_term", "")

    new_filtered_statuses =
      cond do
        only_invited and only_dropped -> []
        only_dropped -> [:dropped]
        only_invited -> [:invited]
        true -> default_filtered_statuses()
      end

    socket
    |> assign(:filtered_statuses, new_filtered_statuses)
    |> then(fn socket ->
      if byte_size(search_term) >= 3 do
        assign(socket, :search_term, search_term)
      else
        assign(socket, :search_term, @empty_search_term)
      end
    end)
    |> refetch_paginated_participants()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("validate-invitation-email", params, socket) do
    Changeset.cast({%{}, %{email: :string}}, params, [:email])
    |> Emails.validate_email_format()
    |> set_error_msg(socket)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("send-invite", _params, %{assigns: %{can_manage_tournament: false}} = socket) do
    socket
    |> put_flash(:error, "You can't perform this action")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("send-invite", %{"email" => email}, socket) do
    %{tournament: tournament} = socket.assigns

    case TournamentRegistrations.invite_participant_to_tournament(tournament, email) do
      {:ok, _tournament_participant} ->
        socket
        |> assign(validation_msg: "")
        |> put_flash(:info, "Successfully sent invitation to #{email}")
        |> push_navigate(to: ~p"/tournament/#{tournament.slug}/participants")

      _error ->
        socket
        |> put_flash(
          :error,
          "Unable to send an invitation to #{email}. Please reload the page and try again."
        )
    end
    |> then(&{:noreply, &1})
  end

  defp set_error_msg(changeset, socket) do
    case get_error_msg(changeset) do
      msg when %{} == msg -> assign(socket, validation_invite_email: "")
      %{email: msg} -> assign(socket, validation_invite_email: msg)
    end
  end

  defp get_error_msg(changeset) do
    Changeset.traverse_errors(changeset, &elem(&1, 0))
  end

  defp default_filtered_statuses, do: Tournaments.on_track_statuses()
end
