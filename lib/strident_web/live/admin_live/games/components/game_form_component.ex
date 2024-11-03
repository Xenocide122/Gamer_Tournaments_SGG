defmodule StridentWeb.Components.GameFormComponent do
  @moduledoc """
    LV to allow for the enabling and editing of supported game titles
  """
  use StridentWeb, :live_component

  alias Ecto.Changeset
  alias Strident.Games
  alias Strident.Games.Game
  alias Strident.SimpleS3Upload

  @impl true
  def update(%{game: game} = assigns, socket) do
    changeset = Games.change_game(game)

    socket =
      socket
      |> assign(assigns)
      |> assign(:action, :edit)
      |> assign(:changeset, changeset)
      |> assign(:genres, Games.list_genres())
      |> allow_upload(:banner,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )
      |> allow_upload(:cover,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )
      |> allow_upload(:logo,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    changeset = Games.change_game(%Game{})

    socket =
      socket
      |> assign(assigns)
      |> assign(:action, :new)
      |> assign(game: nil)
      |> assign(:changeset, changeset)
      |> assign(:genres, Games.list_genres())
      |> allow_upload(:banner,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )
      |> allow_upload(:cover,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )
      |> allow_upload(:logo,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"game" => game_params} = params, socket) do
    game =
      if is_nil(socket.assigns.game),
        do: %Game{},
        else: socket.assigns.game

    game_params = Map.put(game_params, "genres", Map.keys(Map.get(params, "genre", %{})))

    changeset =
      game
      |> Games.change_game(game_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"game" => game_params} = params, socket) do
    save_game(socket, game_params, Map.keys(Map.get(params, "genre", %{})))
  end

  def handle_event("remove-photo", %{"ref" => ref}, socket) do
    socket
    |> cancel_upload(:banner, ref)
    |> then(&{:noreply, &1})
  end

  defp save_game(%{assigns: %{action: :edit}} = socket, game_params, associated_genres) do
    game_params =
      game_params
      |> maybe_add_image_url(socket)
      |> maybe_add_cover_url(socket)
      |> maybe_add_logo_url(socket)
      |> Map.put("genres", associated_genres)

    case Games.update_game(socket.assigns.game, game_params) do
      {:ok, game} ->
        consume_photos(socket, game)

        {:noreply,
         socket
         |> put_flash(:info, "Game updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_game(%{assigns: %{action: :new}} = socket, game_params, associated_genres) do
    game_params =
      game_params
      |> maybe_add_image_url(socket)
      |> maybe_add_cover_url(socket)
      |> maybe_add_logo_url(socket)
      |> Map.put("genres", associated_genres)

    case Games.create_game(game_params) do
      {:ok, game} ->
        consume_photos(socket, game)

        {:noreply,
         socket
         |> put_flash(:info, "Game updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp maybe_add_image_url(attrs, socket) do
    case get_img_params(socket, :banner) do
      [%{url: url}] ->
        Map.put(attrs, "default_game_banner_url", url)

      _ ->
        attrs
    end
  end

  defp maybe_add_cover_url(attrs, socket) do
    case get_img_params(socket, :cover) do
      [%{url: url}] ->
        Map.put(attrs, "cover_image_url", url)

      _ ->
        attrs
    end
  end

  defp maybe_add_logo_url(attrs, socket) do
    case get_img_params(socket, :logo) do
      [%{url: url}] ->
        Map.put(attrs, "logo_url", url)

      _ ->
        attrs
    end
  end

  defp get_img_params(socket, img) do
    {completed, []} = uploaded_entries(socket, img)
    base_aws_key = "games/"

    for entry <- completed do
      %{url: SimpleS3Upload.host() <> "/" <> base_aws_key <> s3_key(entry)}
    end
  end

  def consume_photos(socket, %Game{} = game) do
    consume_uploaded_entries(socket, :banner, fn _meta, _entry -> {:ok, game} end)
    {:ok, game}
  end

  defp presign_entry(entry, socket) do
    base_aws_key = "games/"
    key = base_aws_key <> s3_key(entry)
    uploads = socket.assigns.uploads

    file_size = uploads[entry.upload_config].max_file_size

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(
        key: key,
        content_type: entry.client_type,
        max_file_size: file_size,
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
  defp error_to_string(:external_client_failure), do: "External client failure"

  defp genre_enabled?(changeset, genre) do
    genres = Changeset.get_field(changeset, :game_genres, [])

    Enum.any?(genres, &(&1.genre_id == genre.id))
  end
end
