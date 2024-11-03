defmodule StridentWeb.TournamentRegistrationLive.Components.CreateRosterForm do
  @moduledoc false

  require Logger
  use StridentWeb, :live_component
  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.Parties
  alias Strident.Parties.Party
  alias Strident.Parties.PartyInvitation
  alias Strident.Search
  alias Strident.SimpleS3Upload
  alias Strident.StringUtils

  @init_search_assigns %{users_search_term: "", users_search_results: []}

  @impl true
  def mount(socket) do
    socket
    |> assign(@init_search_assigns)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(
        %{
          id: id,
          tournament: tournament,
          user_return_to: return_to,
          current_page: current_page,
          current_user: current_user,
          next: next,
          previous: previous,
          changeset: changeset,
          party_attrs: party_attrs
        } = assigns,
        socket
      ) do
    socket
    |> copy_parent_assigns(assigns)
    |> assign_new(:selected_users, fn -> [current_user] end)
    |> assign(party_attrs: party_attrs)
    |> assign(current_page: current_page)
    |> assign(next: next)
    |> assign(previous: previous)
    |> assign(:user_return_to, return_to)
    |> assign(:id, id)
    |> assign(:tournament, tournament)
    |> assign(:changeset, changeset)
    |> assign_recently_played_users()
    |> allow_upload(:party_photo,
      accept: ~w(.png .jpg .jpeg),
      max_entries: 1,
      auto_upload: true,
      external: &presign_entry/2
    )
    |> then(&{:ok, &1})
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
  def handle_event("pick", params, socket) do
    %{"id" => user_id} = params
    add_roster_member(socket, user_id)
  end

  @impl true
  def handle_event("add-roster-member", params, socket) do
    %{"user-id" => user_id} = params
    add_roster_member(socket, user_id)
  end

  @impl true
  def handle_event("select-recent-member", params, socket) do
    if Enum.any?(params) do
      %{"_target" => [member_id]} = params
      %{assigns: %{recently_played_users: recently_played_users}} = socket
      user = Enum.find(recently_played_users, &(&1.id == member_id))

      case Map.get(params, member_id) do
        "true" ->
          select_user(socket, user)

        "false" ->
          remove_user_from_party_attrs(socket, user)
      end
    else
      socket
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-photo", %{"ref" => ref}, socket) do
    socket
    |> cancel_upload(:party_photo, ref)
    |> update(:changeset, &Changeset.put_change(&1, :logo_url, nil))
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("cancel", _, socket) do
    %{assigns: %{user_return_to: user_return_to}} = socket

    socket
    |> push_navigate(to: "#{user_return_to}")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("validate", %{"party" => party_attrs}, socket) do
    socket
    |> validate(party_attrs)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-invitation", params, socket) do
    %{"idx" => idx_string} = params
    %{party_attrs: party_attrs} = socket.assigns
    %{"party_invitations" => party_invitations} = party_attrs

    new_party_invitations = Map.drop(party_invitations, [idx_string])
    new_party_attrs = Map.put(party_attrs, "party_invitations", new_party_invitations)

    socket
    |> validate(new_party_attrs)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("add-invitation", _, socket) do
    changeset =
      socket.assigns.changeset
      |> EctoNestedChangeset.append_at([:party_invitations], %PartyInvitation{})

    socket
    |> assign(:changeset, changeset)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("next", %{"current-page" => current_page}, socket) do
    %{party_attrs: party_attrs, selected_users: selected_users} = socket.assigns
    send(self(), {:party, party_attrs, current_page, selected_users})
    {:noreply, socket}
  end

  defp add_roster_member(socket, user_id) do
    %{users_search_results: results} = socket.assigns
    user = Enum.find(results, &(&1.id == user_id))

    if user do
      socket
      |> select_user(user)
      |> assign(@init_search_assigns)
      |> then(&{:noreply, &1})
    else
      socket
      |> put_flash(:error, "Something went wrong. Please try again.")
      |> then(&{:noreply, &1})
    end
  end

  defp validate(socket, party_attrs) do
    changeset =
      %Party{}
      |> Parties.change_party(party_attrs)
      |> validate_unique_emails(party_attrs)
      |> validate_unique_user_ids(party_attrs)
      |> Map.put(:action, :validate)

    socket
    |> assign(:changeset, changeset)
    |> assign(:party_attrs, party_attrs)
  end

  defp select_user(socket, user) do
    %{party_attrs: party_attrs} = socket.assigns
    idx = get_next_empty_slot_index(socket.assigns.changeset)
    party_params = add_user_to_party_attrs(party_attrs, user, "#{idx}")

    socket
    |> update(:selected_users, &Enum.uniq_by([user | &1], fn x -> x.id end))
    |> validate(party_params)
  end

  defp remove_user_from_party_attrs(socket, user) do
    idx = get_invitation_slot_for_user(socket.assigns.changeset, user)
    party_params = remove_from_party_attrs(socket.assigns.party_attrs, "#{idx}")
    validate(socket, party_params)
  end

  defp add_user_to_party_attrs(party_attrs, user, idx) do
    update_in(
      party_attrs,
      ["party_invitations", idx],
      fn _ -> %{"email" => nil, "status" => "pending", "user_id" => user.id} end
    )
  end

  defp remove_from_party_attrs(party_attrs, idx) do
    update_in(
      party_attrs,
      ["party_invitations", idx],
      fn _ -> %{"email" => nil, "status" => "pending", "user_id" => nil} end
    )
  end

  defp get_next_empty_slot_index(changeset) do
    party_invitations = Changeset.get_change(changeset, :party_invitations)
    next_empty_index = Enum.find_index(party_invitations, &is_empty_slot?/1)
    next_empty_index || Enum.count(party_invitations)
  end

  defp is_empty_slot?(party_invitation) do
    email = Changeset.get_change(party_invitation, :email)
    user_id = Changeset.get_change(party_invitation, :user_id)
    StringUtils.is_empty?(email) and StringUtils.is_empty?(user_id)
  end

  defp get_invitation_slot_for_user(changeset, user) do
    changeset
    |> Changeset.get_change(:party_invitations)
    |> Enum.with_index()
    |> Enum.reduce_while(changeset, &get_slot(&1, &2, user))
  end

  defp get_slot({party_invitation, party_invitation_index}, changeset, user) do
    changeset_email = Changeset.get_change(party_invitation, :email)
    changeset_user_id = Changeset.get_change(party_invitation, :user_id)

    is_for_this_user =
      (is_binary(changeset_email) and changeset_email == user.email) or
        (is_binary(changeset_user_id) and changeset_user_id == user.id)

    if is_for_this_user do
      {:halt, party_invitation_index}
    else
      {:cont, changeset}
    end
  end

  defp assign_recently_played_users(socket) do
    %{assigns: %{current_user: current_user}} = socket

    current_user
    |> Parties.list_party_members_user_play_with()
    |> then(&assign(socket, :recently_played_users, &1))
  end

  defp is_member_selected?(user, changeset) do
    changeset
    |> Changeset.get_change(:party_invitations)
    |> Enum.any?(&(Changeset.get_change(&1, :user_id) == user.id))
  end

  defp presign_entry(entry, socket) do
    %{assigns: %{uploads: uploads, changeset: changeset}} = socket
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
    logo_url = SimpleS3Upload.host() <> "/" <> key

    socket
    |> assign(:changeset, Changeset.put_change(changeset, :logo_url, logo_url))
    |> update(:party_attrs, &Map.put(&1, "logo_url", logo_url))
    |> then(&{:ok, meta, &1})
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp s3_key(entry), do: "#{entry.uuid}.#{ext(entry)}"

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp error_to_string(unexpected_error) do
    Logger.warning("Unexpected error in `error_to_string`: #{inspect(unexpected_error)}")
    "Unexpected error while uploading file"
  end

  defp are_all_invitations_filled?(changeset) do
    for invitation <- Changeset.get_change(changeset, :party_invitations), reduce: true do
      boolean ->
        boolean and is_binary(Changeset.get_change(invitation, :email))
    end
  end

  defp validate_unique_emails(changeset, params) do
    %{"party_invitations" => party_invitations} = params

    emails =
      for {_idx, %{"email" => email}} <- party_invitations, reduce: [] do
        emails -> if StringUtils.is_empty?(email), do: emails, else: [email | emails]
      end

    duplicate_emails = emails -- Enum.uniq(emails)

    Changeset.update_change(changeset, :party_invitations, fn party_invitation_changesets ->
      for party_invitation_changeset <- party_invitation_changesets do
        if Changeset.get_change(party_invitation_changeset, :email) in duplicate_emails do
          Changeset.add_error(
            party_invitation_changeset,
            :email,
            "You have already added this email"
          )
        else
          party_invitation_changeset
        end
      end
    end)
  end

  defp validate_unique_user_ids(changeset, params) do
    %{"party_invitations" => party_invitations} = params

    user_ids =
      for {_idx, %{"user_id" => user_id}} <- party_invitations, reduce: [] do
        user_ids -> if StringUtils.is_empty?(user_id), do: user_ids, else: [user_id | user_ids]
      end

    duplicate_user_ids = user_ids -- Enum.uniq(user_ids)

    Changeset.update_change(changeset, :party_invitations, fn party_invitation_changesets ->
      for party_invitation_changeset <- party_invitation_changesets do
        if Changeset.get_change(party_invitation_changeset, :user_id) in duplicate_user_ids do
          Changeset.add_error(
            party_invitation_changeset,
            :user_id,
            "You have already added this user"
          )
        else
          party_invitation_changeset
        end
      end
    end)
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
