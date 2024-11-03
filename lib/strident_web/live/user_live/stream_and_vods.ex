defmodule StridentWeb.UserLive.StreamAndVods do
  @moduledoc false
  use StridentWeb, :live_component
  alias Ecto.Changeset
  alias Strident.Accounts.User
  alias Strident.SocialMedia
  alias Strident.SocialMedia.SocialMediaLink
  alias Strident.StringUtils

  @impl true
  def mount(socket) do
    socket
    |> assign(:edit, false)
    |> then(&{:ok, &1})
  end

  @impl true
  def update(%{user: user, current_user: current_user} = assigns, socket) do
    current_user_is_user = !!current_user && current_user.id == user.id
    twitch_sml = twitch_link(user)
    youtube_sml = youtube_link(user)

    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      current_user_is_user: current_user_is_user,
      twitch_sml: twitch_sml,
      youtube_sml: youtube_sml
    })
    |> assign_any_links()
    |> assign_youtube_video_ids()
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("toggle-edit", _params, socket) do
    socket
    |> toggle_edit()
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-link", %{"link" => id}, socket) do
    link =
      case socket do
        %{assigns: %{twitch_sml: %{id: ^id} = twitch}} -> twitch
        %{assigns: %{youtube_sml: %{id: ^id} = youtube}} -> youtube
      end

    case SocialMedia.delete_social_media_link(link) do
      {:ok, %{brand: :twitch}} ->
        socket
        |> assign(:twitch_sml, nil)

      {:ok, %{brand: brand}} when brand in [:youtube, :youtubechannel] ->
        socket
        |> assign(:youtube_sml, nil)

      _ ->
        socket
        |> put_flash(:error, "Can't remove this link")
    end
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("submit", %{"urls" => urls}, socket) do
    attrs_list = build_attrs_list(urls)

    case SocialMedia.upsert_social_media_links_for_user(socket.assigns.current_user, attrs_list) do
      {:ok, results} ->
        for {{brand, :social_media_link}, sml} <- results, reduce: socket do
          socket ->
            case brand do
              :twitch -> assign(socket, :twitch_sml, sml)
              _ -> assign(socket, :youtube_sml, sml)
            end
        end
        |> assign_any_links()
        |> assign_youtube_video_ids()
        |> toggle_edit()
        |> then(&{:noreply, &1})

      {:error, _, %Changeset{} = changeset, _} ->
        socket
        |> put_humanized_changeset_errors_in_flash(changeset, exclude_field: true)
        |> then(&{:noreply, &1})
    end
  end

  @spec toggle_edit(Socket.t()) :: Socket.t()
  defp toggle_edit(socket) do
    assign(socket, :edit, !socket.assigns.edit)
  end

  @spec build_attrs_list(map()) :: [SocialMedia.sml_attrs()]
  defp build_attrs_list(%{"youtube" => youtube_url, "twitch" => twitch_url}) do
    twitch_handle = extract_sml_handle(twitch_url, ["twitch.tv/"])
    youtube_handle = extract_sml_handle(youtube_url, ["youtube.com/channel/", "youtube.com/c/"])

    youtube_brand =
      if String.contains?(youtube_url, "youtube.com/channel/"),
        do: :youtubechannel,
        else: :youtube

    []
    |> then(fn attrs_list ->
      if StringUtils.is_empty?(twitch_handle),
        do: attrs_list,
        else: [%{brand: :twitch, handle: twitch_handle} | attrs_list]
    end)
    |> then(fn attrs_list ->
      if StringUtils.is_empty?(youtube_handle),
        do: attrs_list,
        else: [
          %{
            brand: youtube_brand,
            handle: youtube_handle,
            updated_brands: [:youtube, :youtubechannel]
          }
          | attrs_list
        ]
    end)
  end

  @spec extract_sml_handle(String.t(), [String.t()]) :: String.t() | nil
  defp extract_sml_handle(url, domains) do
    Enum.reduce_while(domains, url, fn domain, url ->
      case String.split(url, domain, parts: 2) do
        [_, url_suffix] -> url_suffix |> Path.split() |> List.first() |> then(&{:halt, &1})
        [unsplit_url] -> {:cont, unsplit_url}
      end
    end)
  end

  @spec twitch_link(User.t()) :: SocialMediaLink.t() | nil
  defp twitch_link(user), do: Enum.find(user.social_media_links, &(&1.brand == :twitch))
  @spec youtube_link(User.t()) :: SocialMediaLink.t() | nil
  defp youtube_link(user),
    do: Enum.find(user.social_media_links, &(&1.brand in [:youtube, :youtubechannel]))

  @spec any_links?(Socket.t()) :: boolean()
  defp any_links?(socket),
    do: not (is_nil(socket.assigns.twitch_sml) and is_nil(socket.assigns.youtube_sml))

  @spec assign_any_links(Socket.t()) :: Socket.t()
  defp assign_any_links(socket), do: assign(socket, :any_links, any_links?(socket))

  defp assign_youtube_video_ids(socket) do
    youtube_video_ids =
      if socket.assigns.youtube_sml do
        Strident.Youtube.get_playlist_video_ids_for_channel_id_or_username(
          socket.assigns.youtube_sml.handle,
          8
        )
      else
        []
      end

    assign(socket, :youtube_video_ids, youtube_video_ids)
  end
end
