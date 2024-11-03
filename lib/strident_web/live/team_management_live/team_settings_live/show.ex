defmodule StridentWeb.TeamSettingsLive.Show do
  @moduledoc false
  use StridentWeb, :live_view

  alias Strident.SocialMedia
  alias Strident.Teams
  alias Strident.Teams.Team
  alias StridentWeb.TeamLive.Components
  alias Phoenix.LiveView.JS

  on_mount(StridentWeb.TeamManagment.Setup)

  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    {:ok, assign_socket(socket, slug, params)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def assign_socket(socket, slug, _params) do
    team = socket.assigns.team
    email_changeset = Teams.change_team_email(team)

    socket
    |> assign(:team_site, :settings)
    |> assign(:email_changeset, email_changeset)
    |> assign(confirmation_id: nil)
    |> assign(slug: slug)
    |> assign_page_title()
    |> update_data(team)
  end

  @impl true
  def handle_event("save", %{"type" => "team_manager"}, socket) do
    current = current(socket.assigns.team_members, :team_manager)
    new = socket.assigns.team_managers

    with {_, _} <- update_members_type(new -- current, :team_manager),
         {_, _} <- update_members_type(current -- new, :player) do
      socket =
        socket
        |> put_flash(:info, "Team Managers updated successfully")
        |> update_data(socket.assigns.team)

      if authorised?(socket.assigns.current_user, socket.assigns.team) do
        {:noreply, socket}
      else
        {:noreply,
         push_navigate(socket,
           to: Routes.live_path(socket, StridentWeb.TeamSettingsLive.Show, socket.assigns.slug)
         )}
      end
    else
      _ ->
        {:noreply,
         put_flash(socket, :error, "Unable to update Team Managers, please contact support")}
    end
  end

  def handle_event("save", %{"type" => "content_manager"}, socket) do
    current = current(socket.assigns.team_members, :content_manager)
    new = socket.assigns.content_managers

    with {_, _} <- update_members_type(new -- current, :content_manager),
         {_, _} <- update_members_type(current -- new, :player) do
      socket =
        socket
        |> put_flash(:info, "Team Managers updated successfully")
        |> update_data(socket.assigns.team)

      {:noreply, socket}
    else
      _ ->
        {:noreply,
         put_flash(socket, :error, "Unable to update Team Managers, please contact support")}
    end
  end

  def handle_event("save", %{"type" => "social"}, socket) do
    current = socket.assigns.team.social_media_links
    new = socket.assigns.team_socials

    with socket <- add_socials_to_team(socket, new -- current),
         socket <- remove_socials_from_team(socket, current -- new) do
      team = Teams.get_team_with_preloads_by([id: socket.assigns.team.id], social_media_links: [])

      socket =
        socket
        |> assign(team: team)
        |> update_data(team)
        |> put_flash(:info, "Social Media updated successfully")

      {:noreply, socket}
    end
  end

  def handle_event("update_email", %{"team" => params}, socket) do
    team = Teams.get_team_with_preloads_by([id: socket.assigns.team.id], social_media_links: [])

    case Teams.update_team(team, params) do
      {:ok, team} ->
        socket =
          socket
          |> assign(:email_changeset, Teams.change_team_email(team))
          |> update_data(team)
          |> assign(team: team)
          |> put_flash(:info, "Email successfully updated")

        {:noreply, push_event(socket, "email-updated", %{id: "view-email"})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("cancel_email_update", _, socket) do
    socket = assign(socket, :email_changeset, Teams.change_team_email(socket.assigns.team))
    {:noreply, socket}
  end

  def handle_event("add", %{"id" => id, "type" => "team_manager"}, socket) do
    team_managers = add_to_list(socket.assigns.team_managers, id, socket.assigns.team_members)
    {:noreply, assign(socket, team_managers: team_managers)}
  end

  def handle_event("add", %{"id" => id, "type" => "content_manager"}, socket) do
    content_managers =
      add_to_list(socket.assigns.content_managers, id, socket.assigns.team_members)

    {:noreply, assign(socket, content_managers: content_managers)}
  end

  def handle_event("add_social", %{"url" => url}, socket) do
    url = URI.parse(url)
    handle = String.trim_leading(url.path, "/")

    case SocialMedia.get_brand(url.host) do
      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}

      brand ->
        team_socials = [
          %{id: "#{brand}_#{handle}", brand: brand, handle: handle} | socket.assigns.team_socials
        ]

        {:noreply, assign(socket, team_socials: team_socials)}
    end
  end

  def handle_event("confirm_removal", %{"remove-me" => "on", "id" => id}, socket) do
    team_managers = remove_from_list(socket.assigns.team_managers, id)

    socket =
      socket
      |> assign(team_managers: team_managers)
      |> clear_flash()
      |> push_event("confirmation-required", %{})

    {:noreply, socket}
  end

  def handle_event("confirm_removal", _, socket) do
    {:noreply, put_flash(socket, :error, "Please confirm you wish to remove yourself")}
  end

  def handle_event(
        "remove",
        %{"id" => id, "user-id" => user_id, "type" => "team_manager"},
        socket
      ) do
    if Ecto.UUID.cast!(user_id) == socket.assigns.current_user.id do
      socket = assign(socket, confirmation_id: id)
      {:noreply, push_event(socket, "confirmation-required", %{})}
    else
      team_managers = remove_from_list(socket.assigns.team_managers, id)
      {:noreply, assign(socket, team_managers: team_managers)}
    end
  end

  def handle_event("remove", %{"id" => id, "type" => "content_manager"}, socket) do
    content_managers = remove_from_list(socket.assigns.content_managers, id)
    {:noreply, assign(socket, content_managers: content_managers)}
  end

  def handle_event("remove", %{"id" => id, "type" => "social"}, socket) when is_binary(id) do
    team_socials = Enum.filter(socket.assigns.team_socials, fn s -> s.id != id end)
    {:noreply, assign(socket, team_socials: team_socials)}
  end

  def handle_event("remove", %{"id" => id, "type" => "social"}, socket) do
    team_socials =
      Enum.filter(socket.assigns.team_socials, fn s -> s.id != Ecto.UUID.cast!(id) end)

    {:noreply, assign(socket, team_socials: team_socials)}
  end

  def handle_event("update_cancel", %{"type" => "team_manager"}, socket) do
    team_managers = current(socket.assigns.team_members, :team_manager)
    {:noreply, assign(socket, team_managers: team_managers)}
  end

  def handle_event("update_cancel", %{"type" => "content_manager"}, socket) do
    content_managers = current(socket.assigns.team_members, :content_manager)
    {:noreply, assign(socket, content_managers: content_managers)}
  end

  def handle_event("update_cancel", %{"type" => "social"}, socket) do
    {:noreply, assign(socket, team_socials: socket.assigns.team.social_media_links)}
  end

  def handle_event("validate_email", %{"team" => params}, socket) do
    changeset =
      %Team{}
      |> Teams.change_team_email(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, email_changeset: changeset)}
  end

  @impl true
  def handle_info({:team_updated, %{logo_url: url}}, socket) do
    socket
    |> assign(logo_url: url)
    |> clear_flash()
    |> then(&{:noreply, &1})
  end

  defp authorised?(user, team) do
    Teams.can_user_edit?(user, team)
  end

  defp remove_socials_from_team(socket, socials_to_remove) do
    case SocialMedia.delete_social_media_link_team_from_list(socials_to_remove) do
      {number_deleted, _} ->
        put_flash(socket, :info, "deleted #{number_deleted} associated social media accounts")
    end
  end

  defp add_socials_to_team(socket, new_socials) do
    socials = SocialMedia.create_social_media_links(new_socials)

    social_media_links =
      Enum.reduce(socials, [], fn
        {:error, _}, acc -> acc
        {:ok, social}, acc -> [social | acc]
      end)

    social_media_links_team =
      SocialMedia.create_social_media_link_team_assoc_from_list(
        socket.assigns.team,
        social_media_links
      )

    socials_errors =
      Enum.filter(socials, fn
        {:error, _} -> true
        _ -> false
      end)

    social_media_links_team_errors =
      Enum.filter(social_media_links_team, fn
        {:error, _} -> true
        _ -> false
      end)

    errors = socials_errors ++ social_media_links_team_errors

    if Enum.empty?(errors) do
      socket
    else
      put_flash(socket, :error, Enum.join(build_error_msg(errors), ", "))
    end
  end

  defp update_members_type(list, type) when is_list(list) and is_atom(type) do
    list
    |> Enum.map(& &1.id)
    |> Teams.update_team_members_types(type)
  end

  defp update_data(socket, team) do
    team_members = Teams.list_team_members_with_preloads_by([team_id: team.id], user: [])
    team_managers = current(team_members, :team_manager)
    content_managers = current(team_members, :content_manager)
    team_socials = team.social_media_links

    socket
    |> assign(team_members: team_members)
    |> assign(team_managers: team_managers)
    |> assign(content_managers: content_managers)
    |> assign(team_socials: team_socials)
  end

  defp remove_from_list(list, id) when is_list(list) do
    Enum.filter(list, fn i ->
      Ecto.UUID.cast!(i.id) != id
    end)
  end

  defp add_to_list(current, id, pool) do
    current = Enum.reverse(current)

    Enum.reverse([Enum.find(pool, &(Ecto.UUID.cast!(&1.id) == id)) | current])
  end

  defp current(pool, filter) do
    Enum.filter(pool, &(&1.type == filter))
  end

  defp assign_page_title(%{assigns: %{team: team}} = socket) do
    assign(socket, page_title: team.name)
  end

  defp build_error_msg(errors) do
    Enum.map(errors, fn {:error, changeset} ->
      %{brand: brand, handle: handle} = changeset.changes
      "We are unable to create a social media account at #{brand} with handle #{handle}"
    end)
  end
end
