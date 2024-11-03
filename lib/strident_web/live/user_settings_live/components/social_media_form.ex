defmodule StridentWeb.UserSettingsLive.SocialMediaForm do
  @moduledoc false
  use StridentWeb, :live_component
  alias Ecto.Changeset
  alias Strident.Accounts
  alias Strident.SocialMedia
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.SocialMedia.SocialMediaLinkUser

  @impl true
  def mount(socket) do
    socket
    |> assign(%{updated: false})
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{current_user: current_user} = assigns, socket) do
    user_with_socials =
      Accounts.get_user_with_preloads_by([id: current_user.id], [
        :social_media_links,
        :teams,
        :featured_team
      ])
      |> set_social_media_virtual_fields()

    socket
    |> copy_parent_assigns(assigns)
    |> assign(current_user: user_with_socials)
    |> assign_new(:changeset, fn -> Accounts.change_user_details(user_with_socials) end)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event(
        "update-user-details",
        %{"user" => params},
        %{assigns: %{current_user: user}} = socket
      ) do
    params =
      Map.update(
        params,
        "social_media_link_user",
        %{},
        &build_social_media_changes(Map.to_list(&1), user.social_media_link_user)
      )

    case Accounts.update_user_details(user, params) do
      {:ok, %{social_media_updates: updated_links, user_details_update: updated_details}} ->
        updated_user =
          updated_details
          |> Map.put(:social_media_link_user, updated_links)
          |> Map.put(:social_media_links, Enum.map(updated_links, & &1.social_media_link))

        socket
        |> assign(
          current_user: updated_user,
          changeset: Accounts.change_user_details(updated_user)
        )
        |> then(&{:noreply, &1})

      {:ok, %{user_details_update: updated_details}} ->
        updated_user =
          updated_details
          |> Map.put(:social_media_link_user, user.social_media_link_user)
          |> Map.put(:social_media_links, user.social_media_links)

        socket
        |> assign(
          current_user: updated_user,
          changeset: Accounts.change_user_details(updated_user)
        )
        |> then(&{:noreply, &1})

      _ ->
        socket
        |> put_flash(:error, "Could not update user details")
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("add-new-social-media", _params, %{assigns: %{changeset: changeset}} = socket) do
    {:noreply, assign(socket, changeset: add_new_social_media_link_user(changeset))}
  end

  @impl true
  def handle_event(
        "remove-social-media",
        %{"index" => index},
        %{assigns: %{changeset: changeset, current_user: user}} = socket
      ) do
    index = String.to_integer(index)

    changeset =
      if index < length(user.social_media_link_user) do
        set_delete_social_media_link_user(changeset, index)
      else
        remove_social_media_link_user(changeset, index)
      end

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "validate-social-media",
        %{"user" => params},
        %{assigns: %{current_user: user}} = socket
      ) do
    params =
      Map.update(
        params,
        "social_media_link_user",
        %{},
        &build_social_media_changes(Map.to_list(&1), user.social_media_link_user)
      )

    changeset = Accounts.change_user_details(user, params)

    {:noreply, assign(socket, changeset: changeset)}
  end

  defp my_teams(%{teams: teams}) do
    Enum.map(teams, &{&1.name, &1.id})
  end

  defp set_social_media_virtual_fields(user) do
    Map.update(
      user,
      :social_media_link_user,
      [],
      &Enum.map(&1, fn %{social_media_link: sml} = smlu ->
        input = SocialMedia.url(sml.brand, sml.handle)

        %{
          smlu
          | social_media_link: Map.merge(sml, %{user_input: input, delete: false})
        }
      end)
    )
  end

  defp add_new_social_media_link_user(changeset) do
    social_media =
      [
        build_social_media()
        | Changeset.get_change(
            changeset,
            :social_media_link_user,
            Changeset.get_field(changeset, :social_media_link_user, [])
          )
      ]
      |> Enum.slide(0, -1)

    Changeset.put_assoc(changeset, :social_media_link_user, social_media)
  end

  defp remove_social_media_link_user(changeset, index) do
    social_media =
      List.delete_at(
        Changeset.get_change(
          changeset,
          :social_media_link_user,
          Changeset.get_field(changeset, :social_media_link_user, [])
        ),
        index
      )

    Changeset.put_assoc(changeset, :social_media_link_user, social_media)
  end

  defp set_delete_social_media_link_user(changeset, index) do
    social_media =
      List.update_at(
        Changeset.get_change(
          changeset,
          :social_media_link_user,
          Changeset.get_field(changeset, :social_media_link_user, [])
        ),
        index,
        &delete_social_media_change/1
      )

    Changeset.put_assoc(changeset, :social_media_link_user, social_media)
  end

  defp build_social_media(attrs \\ %{}) do
    %SocialMediaLinkUser{}
    |> Changeset.change()
    |> Changeset.put_assoc(
      :social_media_link,
      SocialMediaLink.cast_user_input(%SocialMediaLink{}, attrs)
    )
  end

  defp delete_social_media_change(media_link_user) do
    media_link = get_social_media_link(media_link_user)

    media_link_user
    |> Changeset.change()
    |> Changeset.put_assoc(
      :social_media_link,
      SocialMediaLink.cast_user_input(media_link, %{delete: true})
    )
  end

  defp get_social_media_link(%SocialMediaLinkUser{} = media_link_user) do
    Map.get(media_link_user, :social_media_link)
  end

  defp get_social_media_link(media_link_user) do
    Changeset.get_change(
      media_link_user,
      :social_media_link,
      Changeset.get_field(media_link_user, :social_media_link)
    )
  end

  defp build_social_media_changes([{_index, %{"social_media_link" => updated_link}} | params], [
         old_link | existing_social_media
       ]) do
    [
      old_link
      |> Changeset.change()
      |> Changeset.put_assoc(
        :social_media_link,
        SocialMediaLink.cast_user_input(old_link.social_media_link, updated_link)
      )
      | build_social_media_changes(params, existing_social_media)
    ]
  end

  defp build_social_media_changes(
         [{_index, %{"social_media_link" => updated_link}} | params],
         []
       ) do
    [build_social_media(updated_link) | build_social_media_changes(params, [])]
  end

  defp build_social_media_changes([], []), do: []
end
