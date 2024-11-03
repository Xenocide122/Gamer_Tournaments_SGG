defmodule StridentWeb.TeamRegistrationLive.New do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.SocialMedia
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.SocialMedia.SocialMediaLinkTeam
  alias Strident.Teams
  alias Strident.Teams.Team
  alias Strident.Teams.TeamUserInvitation
  alias Strident.Teams.TeamUserInvitationUser

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign_socket(socket)}
  end

  @impl true
  def handle_event("back", _params, socket) do
    socket
    |> step_back()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("next", _params, socket) do
    socket
    |> step_next()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event(
        "register-team",
        _params,
        %{assigns: %{current_user: current_user, changeset: changeset}} = socket
      ) do
    case Teams.initialize_team(changeset, current_user) do
      {:ok, _team} ->
        socket
        |> update(:current_step, fn current_step -> current_step + 1 end)
        |> then(&{:noreply, &1})

      {:error, _, changeset, _} ->
        socket
        |> put_humanized_changeset_errors_in_flash(changeset)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event(
        "validate-team-info-step",
        %{"team" => attrs},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    attrs =
      case changeset do
        %{changes: %{logo_url: logo_url}} -> Map.put(attrs, "logo_url", logo_url)
        _ -> attrs
      end

    %Team{}
    |> Teams.change_team(attrs)
    |> then(fn changeset ->
      attrs
      |> Map.get("social_media_link_teams", %{})
      |> Enum.map(fn {_index, %{"social_media_link" => attrs}} -> build_social_media(attrs) end)
      |> then(&Changeset.put_assoc(changeset, :social_media_link_teams, &1))
    end)
    |> then(fn new_changeset ->
      changeset
      |> Changeset.get_field(:team_user_invitations, [])
      |> then(&Changeset.put_assoc(new_changeset, :team_user_invitations, &1))
    end)
    |> Map.put(:action, :validate)
    |> then(&{:noreply, assign(socket, :changeset, &1)})
  end

  @impl true
  def handle_event(
        "validate-team-user-invitations-step",
        %{"team" => attrs},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    attrs
    |> Map.get("team_user_invitations", %{})
    |> Enum.map(fn {_index, attrs} -> build_team_invitation(attrs) end)
    |> then(&Changeset.put_assoc(changeset, :team_user_invitations, &1))
    |> Map.put(:action, :insert)
    |> then(&{:noreply, assign(socket, :changeset, &1)})
  end

  @impl true
  def handle_event("add-new-social-media", _params, %{assigns: %{changeset: changeset}} = socket) do
    {:noreply, assign(socket, :changeset, add_new_social_media_link_team(changeset))}
  end

  @impl true
  def handle_event(
        "add-new-team-user-invitation",
        _param,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply, assign(socket, :changeset, add_new_team_user_invitation(changeset))}
  end

  @impl true
  def handle_info({:team_updated, %{logo_url: logo_url}}, socket) do
    socket
    |> update(:changeset, &Changeset.put_change(&1, :logo_url, logo_url))
    |> then(&{:noreply, &1})
  end

  def assign_socket(socket) do
    socket
    |> assign(:page_title, "Register Team")
    |> assign(:current_step, 1)
    |> assign(:social_media_brands, SocialMedia.brands())
    |> assign_changeset()
  end

  def assign_changeset(socket) do
    assign(socket, :changeset, validate_changeset())
  end

  def step_back(socket) do
    update(socket, :current_step, &max(&1 - 1, 1))
  end

  def validate_changeset(params \\ %{}) do
    %Team{}
    |> Teams.change_team(params)
    |> add_new_social_media_link_team()
    |> add_new_team_user_invitation()
    |> Map.put(:action, :validate)
  end

  @doc """
  On the first step we validate, if in the main changeset there are errors on:
  - name
  - email
  - description
  - or logo_url

  We also validate, that social media that was inputed doesn't have invalid handle or brand,
  but if it is empty, we do not validate it(since it will not be inserted into DB).

  On the second step, similar to social media validation, we validate, that each of emails
  written in was valid(we do not validate empty emails, since they won't be written into DB).
  """
  def step_next(%{assigns: %{current_step: current_step, changeset: changeset}} = socket) do
    new_step =
      if is_page_invalid?(current_step, changeset) do
        current_step
      else
        current_step + 1
      end

    update(socket, :current_step, fn _ -> new_step end)
  end

  defp setup_class_wizard_steps(current_step, step) do
    case current_step do
      current_step when current_step == step -> "active"
      current_step when current_step > step -> "completed"
      _ -> ""
    end
  end

  defp add_new_social_media_link_team(changeset) do
    social_media =
      [build_social_media() | Changeset.get_field(changeset, :social_media_link_teams, [])]
      |> Enum.slide(0, -1)

    Changeset.put_assoc(changeset, :social_media_link_teams, social_media)
  end

  defp add_new_team_user_invitation(changeset) do
    invitations =
      [build_team_invitation() | Changeset.get_field(changeset, :team_user_invitations, [])]
      |> Enum.slide(0, -1)

    Changeset.put_assoc(changeset, :team_user_invitations, invitations)
  end

  defp build_social_media(attrs \\ %{}) do
    %SocialMediaLinkTeam{}
    |> SocialMediaLinkTeam.changeset(%{})
    |> Changeset.put_assoc(
      :social_media_link,
      SocialMediaLink.cast_user_input(%SocialMediaLink{}, attrs)
    )
  end

  defp build_team_invitation(attrs \\ %{}) do
    %TeamUserInvitation{}
    |> TeamUserInvitation.changeset(attrs)
    |> then(fn
      %{changes: %{email: email}} = changeset ->
        case Accounts.get_user_by_email(email) do
          nil ->
            changeset

          user ->
            Changeset.put_assoc(
              changeset,
              :team_user_invitation_user,
              TeamUserInvitationUser.changeset(%TeamUserInvitationUser{}, %{user_id: user.id})
            )
        end

      val ->
        val
    end)
  end

  defp is_logo_url_valid?(changeset) do
    Changeset.get_change(changeset, :logo_url) != nil
  end

  defp show_image_if_valid(changeset) do
    if is_logo_url_valid?(changeset) do
      Changeset.get_change(changeset, :logo_url)
    else
      safe_static_url("/images/file_group.png")
    end
  end

  defp get_users_img(user_id) do
    user_id
    |> Accounts.get_user()
    |> Accounts.avatar_url()
  end

  defp get_users_name(user_id) do
    user_id
    |> Accounts.get_user()
    |> Accounts.user_display_name()
  end

  defp social_media_is_valid?(changeset) do
    changeset
    |> Changeset.get_change(:social_media_link_teams)
    |> Enum.map(&Changeset.get_change(&1, :social_media_link))
    |> Enum.reduce_while(false, fn
      %{changes: %{handle: _handle, brand: _brand}} = val, _ ->
        if errors_with_keys?(val, [:handle, :brand]) do
          {:halt, true}
        else
          {:cont, false}
        end

      _changeset, _ ->
        {:cont, false}
    end)
  end

  defp team_user_invitations_is_valid?(changeset) do
    changeset
    |> Changeset.get_change(:team_user_invitations)
    |> Enum.reduce_while(false, fn
      %{changes: %{email: _email}} = val, _ ->
        if errors_with_keys?(val, [:email]) do
          {:halt, true}
        else
          {:cont, false}
        end

      _changeset, _ ->
        {:cont, false}
    end)
  end

  @spec errors_with_keys?(Changeset.t(), [atom()]) :: boolean()
  defp errors_with_keys?(%{errors: errors}, keys) do
    Enum.any?(keys, &Keyword.has_key?(errors, &1))
  end

  defp is_page_invalid?(1, changeset) do
    social_media_is_valid?(changeset) ||
      errors_with_keys?(changeset, [:name, :email, :description, :logo_url])
  end

  defp is_page_invalid?(2, changeset) do
    team_user_invitations_is_valid?(changeset)
  end

  defp is_page_invalid?(_page, _changeset) do
    false
  end
end
