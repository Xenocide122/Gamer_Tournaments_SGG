defmodule StridentWeb.PartyManagementLive.Index do
  @moduledoc false
  use StridentWeb, :live_view
  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.Accounts.UserNotifier
  alias Strident.Emails
  alias Strident.Parties
  alias Strident.Parties.Party
  alias Strident.Search
  alias Strident.SimpleS3Upload
  alias Strident.Tournaments
  alias Phoenix.LiveView.JS

  @types %{email: :string}
  @init_search_assigns %{users_search_term: "", users_search_results: []}

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:validation_msg, nil)
    |> assign(state: :enabled)
    |> assign(@init_search_assigns)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(%{"tournament" => tournament_id, "id" => party_id}, _url, socket) do
    socket
    |> assign_party_and_tournament_and_current_user_can_manage_ids(party_id)
    |> assign(tournament: Tournaments.get_tournament!(tournament_id))
    |> allow_upload(:party_photo,
      accept: ~w(.png .jpg .jpeg),
      max_entries: 1,
      external: &presign_entry/2
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_params(%{"id" => party_id}, _url, socket) do
    socket
    |> assign_party_and_tournament_and_current_user_can_manage_ids(party_id)
    |> allow_upload(:party_photo,
      accept: ~w(.png .jpg .jpeg),
      max_entries: 1,
      external: &presign_entry/2
    )
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("send-invitation", %{"id" => id}, socket) do
    %{assigns: %{party: party, tournament: tournament}} = socket
    party_invitation = Enum.find(party.party_invitations, &(&1.id == id))

    case UserNotifier.deliver_party_invitation(party_invitation, party, tournament) do
      {:ok, _} ->
        socket
        |> put_flash(:info, "Invitation send succesfully.")
        |> then(&{:noreply, &1})

      {:error, _} ->
        socket
        |> put_flash(:error, "Error sending invitation.")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("send-all-pending-invitations", _params, socket) do
    %{assigns: %{party: party, tournament: tournament}} = socket

    Parties.deliver_all_pending_party_invitations_for_party_by_id(party.id, tournament)

    socket
    |> put_flash(:info, "Party Invitations sent.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("validate-email", params, socket) do
    Changeset.cast({%{}, @types}, params, Map.keys(@types))
    |> Emails.validate_email_format()
    |> set_error_msg(socket)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("send-invite", params, socket) do
    %{"email" => email} = params

    socket
    |> invite_with_email(email)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("update-type", %{"change" => type, "id" => id}, socket) do
    %{assigns: %{party: party}} = socket

    case Enum.find(party.party_members, &(&1.id == id)) do
      nil ->
        socket
        |> put_flash(:error, "This memeber does not exitst!")
        |> then(&{:norepy, &1})

      party_member ->
        type = String.to_existing_atom(type)
        update_party_member(party_member, type, party.party_members, socket)
    end
  end

  @impl true
  def handle_event(
        "drop-party-member",
        %{"id" => id, "player-type" => "party-invitation"},
        socket
      ) do
    drop_entity(id, &Parties.drop_party_invitation/1, socket)
  end

  def handle_event("drop-party-member", %{"id" => id, "player-type" => "party-member"}, socket) do
    %{party: party} = socket.assigns

    if party.party_members
       |> Enum.reject(&(&1.id == id))
       |> will_have_a_manager_or_captain?(:dropped) do
      drop_entity(id, &Parties.drop_party_member/1, socket)
    else
      socket
      |> put_flash(
        :error,
        "Player cannot be dropped as a Party must always have a Captain or Manager"
      )
      |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event(
        "re-invite-party-member",
        %{"id" => id, "player-type" => "party-invitation"},
        socket
      ) do
    %{party: party, tournament: tournament} = socket.assigns
    invitation = Enum.find(party.party_invitations, &(&1.id == id))

    user =
      case invitation do
        %{user_id: nil, email: email} when is_binary(email) -> Accounts.get_user_by_email(email)
        %{user_id: user_id} when is_binary(user_id) -> Accounts.get_user(user_id)
      end

    invitation = %{invitation | user: user, user_id: user.id}

    case Parties.reinvite_party_invitation(invitation, tournament) do
      {:ok, invitation} ->
        update(socket, :party, fn party ->
          updated_party_invitations =
            Enum.map(party.party_invitations, fn inv ->
              if inv.id == invitation.id do
                invitation
              else
                inv
              end
            end)

          %{party | party_invitations: updated_party_invitations}
        end)

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "drop-and-refund",
        _params,
        %{assigns: %{current_user_can_manage_ids: false}} = socket
      ) do
    socket
    |> put_flash(:error, "You can't drop participant.")
    |> then(&{:noreply, &1})
  end

  def handle_event("drop-and-refund", %{"participant" => participant_id}, socket) do
    %{my_participant: participant, party: party, tournament: tournament} = socket.assigns

    with true <- participant.id == participant_id,
         {:ok, _, _} <-
           Tournaments.drop_tournament_participant_from_tournament(participant,
             refund_participant: true,
             notify_to_and_admins: true
           ) do
      socket
      |> put_flash(:info, "#{party.name} was dropped from the tournament.")
      |> push_navigate(to: ~p"/t/#{tournament.slug}")
    else
      false ->
        put_flash(socket, :error, "You can't drop participant.")

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("update-substitute", params, socket) do
    substitute =
      case params do
        %{"change" => "true"} -> true
        %{"change" => "false"} -> false
      end

    %{assigns: %{party: party}} = socket
    party_member = Enum.find(party.party_members, &(&1.id == params["id"]))

    case Parties.update_party_member_type_or_substitute(party_member, %{substitute: substitute}) do
      {:ok, party_member} ->
        %{id: party_member_id} = party_member

        party_members =
          Enum.map(party.party_members, fn
            %{id: ^party_member_id} -> party_member
            party_member -> party_member
          end)

        socket
        |> update(:party, fn party ->
          %{party | party_members: party_members}
        end)
        |> put_flash(:info, "Changed sub")

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error, exclude_field: true)
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("accept-invitation", %{"email" => email, "id" => party_invite_id}, socket) do
    user = Accounts.get_user_by_email(email)
    %{tournament: tournament} = socket.assigns

    current_user_roster_invites = Strident.Rosters.get_users_roster_invites(tournament.id, user)

    case(
      current_user_roster_invites
      |> Enum.split_with(&(&1.id == party_invite_id))
      |> Parties.accept_and_reject_roster_invites_on_tournament(tournament.id, user)
    ) do
      {:ok, results} ->
        party_member =
          Enum.find(results, fn
            {{:party_member, _tp_id}, _party_member} -> true
            _ -> false
          end)
          |> elem(1)

        party =
          Parties.get_party_with_preloads!(party_member.party_id, [
            :party_invitations,
            party_members: [:user]
          ])

        socket
        |> assign(:party, party)
        |> put_flash(
          :info,
          "#{email} invitation successfully accepted."
        )
        |> then(&{:noreply, &1})

      {:error, _, error, _} ->
        socket
        |> put_string_or_changeset_error_in_flash(error)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove-photo", %{"ref" => ref}, socket) do
    socket
    |> cancel_upload(:party_photo, ref)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("upload-new-logo", _params, socket) do
    %{assigns: %{party: party, tournament: tournament}} = socket
    [logo_url] = get_photos_params(socket)

    path =
      Routes.live_path(socket, __MODULE__, party.id, %{
        "tournament" => tournament.id
      })

    case Parties.update_logo_url(party, logo_url, &consume_photos(socket, &1)) do
      {:ok, _photos} ->
        socket
        |> put_flash(:info, "Success! Team logo was updated.")
        |> push_navigate(to: path)
        |> then(&{:noreply, &1})

      {:error, _error} ->
        socket
        |> put_flash(:error, "Can't update Team logo.")
        |> push_navigate(to: path)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("search", %{"value" => value}, socket) when is_binary(value) do
    results = if String.length(value) > 2, do: Search.search_users(value), else: []
    assigns = %{users_search_results: results, users_search_term: value}

    socket
    |> assign(assigns)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("click-away", _params, socket) do
    socket
    |> assign(@init_search_assigns)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-roster-member", params, socket) do
    %{"user-id" => user_id} = params
    %{users_search_results: results} = socket.assigns
    user = Enum.find(results, &(&1.id == user_id))

    if user do
      socket
      |> invite_user_to_party(user)
      |> assign(@init_search_assigns)
      |> then(&{:noreply, &1})
    else
      socket
      |> put_flash(:error, "Something went wrong. Please try again.")
      |> then(&{:noreply, &1})
    end
  end

  defp invite_with_email(socket, email) when is_binary(email) do
    %{party: party, tournament: tournament} = socket.assigns

    case Parties.create_party_invitation_with_email(party, tournament, email) do
      {:ok, party_invitation} ->
        new_invitations = [party_invitation | party.party_invitations]
        new_party = %{party | party_invitations: new_invitations}

        socket
        |> assign(:party, new_party)
        |> put_flash(:info, "Success! You send invitation to #{email}.")

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
  end

  defp invite_user_to_party(socket, user) do
    %{party: party, tournament: tournament} = socket.assigns

    case Parties.create_party_invitation_for_user(party, tournament, user) do
      {:ok, party_invitation} ->
        new_invitations = [party_invitation | party.party_invitations]
        new_party = %{party | party_invitations: new_invitations}

        socket
        |> assign(:party, new_party)
        |> put_flash(:info, "Success! You send invitation to #{user.display_name}.")

      {:error, error} ->
        put_string_or_changeset_error_in_flash(socket, error)
    end
  end

  defp update_party_member(%{type: :manager} = party_member, :manager, party_members, socket) do
    update_party_member(party_member, :captain, party_members, socket)
  end

  defp update_party_member(%{type: :captain} = party_member, :captain, party_members, socket) do
    update_party_member(party_member, :player, party_members, socket)
  end

  defp update_party_member(party_member, type, party_members, socket) do
    with(
      true <-
        party_members
        |> Enum.reject(&(&1.id == party_member.id))
        |> will_have_a_manager_or_captain?(type),
      {:ok, party_member} <- Parties.update_party_member(party_member, %{type: type})
    ) do
      party =
        Parties.get_party_with_preloads!(party_member.party_id, [
          :party_invitations,
          party_members: [:user]
        ])

      socket
      |> assign(party: party)
      |> then(&{:noreply, &1})
    else
      false ->
        socket
        |> put_flash(:error, "The Team must have at least one Manager or Captain")
        |> then(&{:noreply, &1})

      {:error, _error} ->
        socket
        |> put_flash(
          :error,
          "We are unable to update this Players role ... please contact support"
        )
        |> then(&{:noreply, &1})
    end
  end

  defp drop_entity(id, func, socket) do
    case func.(id) do
      {:ok, result} ->
        party =
          Parties.get_party_with_preloads!(result.party_id, [
            :party_invitations,
            party_members: [:user]
          ])

        socket
        |> assign(party: party)
        |> then(&{:noreply, &1})

      {:error, _err} ->
        socket
        |> put_flash(:error, "We are unable to complete this action, please contact support.")
        |> then(&{:noreply, &1})
    end
  end

  defp will_have_a_manager_or_captain?(party_members, type) when type in [:player, :dropped] do
    party_members
    |> Enum.filter(&(&1.type in [:captain, :manager]))
    |> Enum.any?()
  end

  defp will_have_a_manager_or_captain?(_party_members, _type), do: true

  defp set_error_msg(changeset, socket) do
    case get_error_msg(changeset) do
      msg when %{} == msg -> assign(socket, validation_msg: "")
      %{email: msg} -> assign(socket, validation_msg: msg)
    end
  end

  defp get_error_msg(changeset) do
    Changeset.traverse_errors(changeset, &elem(&1, 0))
  end

  defp assign_party_and_tournament_and_current_user_can_manage_ids(socket, party_id) do
    %{tournament_participants: [%{tournament: tournament} = participant]} =
      party =
      Parties.get_party_with_preloads!(party_id, [
        :party_invitations,
        tournament_participants: :tournament,
        party_members: [user: []]
      ])

    user_ids_who_can_manage =
      party.party_members
      |> Enum.filter(&(&1.type in [:manager, :captain]))
      |> Enum.map(& &1.user_id)

    current_user_can_manage_ids =
      case socket.assigns do
        %{current_user: %{id: id}} when is_binary(id) -> id in user_ids_who_can_manage
        _ -> false
      end

    socket
    |> assign(party: party)
    |> assign(tournament: tournament)
    |> assign(current_user_can_manage_ids: current_user_can_manage_ids)
    |> assign(:my_participant, participant)
  end

  defp get_photos_params(socket) do
    {completed, []} = uploaded_entries(socket, :party_photo)
    base_aws_key = "parties/"

    for entry <- completed do
      %{logo_url: SimpleS3Upload.host() <> "/" <> base_aws_key <> s3_key(entry)}
    end
  end

  def consume_photos(socket, %Party{} = party) do
    consume_uploaded_entries(socket, :party_photo, fn _meta, _entry -> {:ok, party} end)
    {:ok, party}
  end

  defp presign_entry(entry, socket) do
    %{assigns: %{uploads: uploads}} = socket
    base_aws_key = "parties/"
    key = base_aws_key <> s3_key(entry)

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads.party_photo.max_file_size,
        expires_in: :timer.hours(1)
      )

    meta = %{uploader: "S3", key: key, url: SimpleS3Upload.host(), fields: fields}
    {:ok, meta, socket}
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp s3_key(entry), do: "#{entry.uuid}.#{ext(entry)}"

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  attr(:id, :string, required: true)
  attr(:party_name, :string, required: true)
  attr(:participant_id, :string, required: true)

  defp drop_team_from_tournament_modal(assigns) do
    ~H"""
    <.modal_small id={@id}>
      <:header>
        <div class="flex items-center justify-center gap-2">
          <img class="mb-2 rounded-b max-h-20" src="/images/font-awesome/alert.svg" alt="alert" />
          Drop <%= @party_name %> from the tournament?
        </div>
      </:header>

      <p class="text-xs text-grey-light">
        Are you sure you want to drop your team? This will remove yourself and all players registered to the team from the tournament.
      </p>

      <:cancel>
        <.button
          id="cancel-button-leave-modal"
          class="rounded border-grey-light text-grey-light"
          phx-click={hide_modal(@id)}
        >
          Cancel
        </.button>
      </:cancel>

      <:confirm>
        <.button
          id={"drop-party-from-tournament-button-#{@participant_id}"}
          button_type={:secondary}
          class="text-white rounded"
          phx-click="drop-and-refund"
          phx-value-participant={@participant_id}
        >
          Drop Team
        </.button>
      </:confirm>
    </.modal_small>
    """
  end

  defp render_user_search_result(assigns) do
    ~H"""
    <div
      class="group flex justify-between items-center p-2 mx-2 cursor-pointer bg-grey-medium border-1 border-primary opacity-70 hover:opacity-100"
      title={"Add new roster member #{@search_result.display_name}"}
      id={"user-search-result-" <> @search_result.id}
      phx-click="add-roster-member"
      phx-value-user-id={@search_result.id}
      phx-target={@phx_target}
    >
      <div class="flex items-center gap-x-4">
        <.image
          id={"user-search-result-avatar-#{@search_result.id}"}
          image_url={@search_result.avatar_url || Accounts.return_default_avatar()}
          alt="logo"
          class="rounded-full"
          width={40}
          height={40}
        />
        <div>
          <%= @search_result.display_name %>
        </div>
      </div>
      <div :if={@search_result.id} class="hidden group-hover:block text-primary">
        Add
      </div>
    </div>
    """
  end
end
