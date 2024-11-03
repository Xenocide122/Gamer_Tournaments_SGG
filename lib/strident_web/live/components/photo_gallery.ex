defmodule StridentWeb.Components.PhotoGallery do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.Accounts.User
  alias Strident.Multimedia
  alias Strident.Multimedia.Photo
  alias Strident.SimpleS3Upload
  alias Phoenix.LiveView.JS

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{upload_for: upload_for} = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:photos, upload_for.photos)
    |> assign_update_for_and_aws(assigns)
    |> assign_can_manage_photo_galery()
    |> assign(:changeset, Photo.changeset(%Photo{}))
    |> allow_upload(:photo,
      accept: ~w(.png .jpg .jpeg),
      max_entries: 10,
      external: &presign_entry/2
    )
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  @impl true
  def handle_event("cancel-all", _params, socket) do
    %{assigns: %{upload_for: upload_for}} = socket
    {:noreply, push_navigate(socket, to: Routes.user_show_path(socket, :show, upload_for.slug))}
  end

  @impl true
  def handle_event("save", _params, socket) do
    %{assigns: %{current_user: current_user, upload_for: upload_for}} = socket
    photos = get_photos_params(socket)

    case Multimedia.create_user_photos(current_user, photos, &consume_photos(socket, &1)) do
      {:ok, _photos} ->
        {:noreply,
         socket
         |> put_flash(:info, "Photos created successfully")
         |> push_navigate(to: Routes.user_show_path(socket, :show, upload_for.slug))}

      {:error, _, %Ecto.Changeset{} = changeset, _} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("remove-photo", %{"photo" => id}, socket) do
    %{assigns: %{photos: photos}} = socket
    photo = Enum.find(photos, &(&1.id == id))

    with {:ok, _aws_photo} <-
           ExAws.S3.delete_object(SimpleS3Upload.bucket(), photo.link) |> ExAws.request(),
         {:ok, _db_photo} <- Multimedia.delete_photo(photo) do
      socket
      |> put_flash(:info, "Photo was removed from your gallery")
      |> update(:photos, &Enum.reject(&1, fn photo -> photo.id == id end))
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> put_flash(:error, "Can't remove photo from gallery")
        |> then(&{:noreply, &1})
    end
  end

  def consume_photos(socket, %Photo{} = photo) do
    consume_uploaded_entries(socket, :photo, fn _meta, _entry -> {:ok, photo} end)
    {:ok, photo}
  end

  defp get_photos_params(socket) do
    {completed, []} = uploaded_entries(socket, :photo)
    base_aws_key = socket.assigns.aws_base_key

    for entry <- completed do
      %{link: base_aws_key <> s3_key(entry)}
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  def assign_update_for_and_aws(%{assigns: %{curent_user: nil}} = socket, _assigns) do
    socket
    |> assign(:upload_for, nil)
    |> assign(:aws_base_key, nil)
  end

  def assign_update_for_and_aws(socket, %{upload_for: %User{}} = assigns) do
    %{upload_for: update_for} = assigns

    socket
    |> assign(:upload_for, update_for)
    |> assign(:aws_base_key, "#{update_for.display_name}/")
  end

  def assign_can_manage_photo_galery(%{assigns: %{current_user: nil}} = socket) do
    assign(socket, :can_manage_photo_galery, false)
  end

  def assign_can_manage_photo_galery(socket) do
    %{assigns: %{upload_for: %User{} = user, current_user: %User{} = current_user}} = socket

    if user.id == current_user.id do
      assign(socket, :can_manage_photo_galery, true)
    else
      assign(socket, :can_manage_photo_galery, false)
    end
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp s3_key(entry), do: "#{entry.uuid}.#{ext(entry)}"

  defp presign_entry(entry, socket) do
    uploads = socket.assigns.uploads
    base_aws_key = socket.assigns.aws_base_key
    key = base_aws_key <> s3_key(entry)

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads.photo.max_file_size,
        expires_in: :timer.hours(1)
      )

    meta = %{uploader: "S3", key: key, url: SimpleS3Upload.host(), fields: fields}
    {:ok, meta, socket}
  end

  def photo_url(photo_link) do
    SimpleS3Upload.host() <> "/" <> photo_link
  end

  def open_edit_opts do
    JS.remove_class("hidden", to: "#upload-photos")
    |> JS.remove_class("hidden", to: "#close-edit-button")
    |> JS.remove_class("hidden", to: "#edit-existing-photos")
    |> JS.add_class("hidden", to: "#edit-button")
    |> JS.add_class("hidden", to: "#show-photos")
    |> JS.add_class("hidden", to: "#no-images-section")
  end

  def close_edit_opts do
    JS.add_class("hidden", to: "#upload-photos")
    |> JS.remove_class("hidden", to: "#edit-button")
    |> JS.remove_class("hidden", to: "#show-photos")
    |> JS.add_class("hidden", to: "#close-edit-button")
    |> JS.add_class("hidden", to: "#edit-existing-photos")
    |> JS.add_class("hidden", to: "#no-images-section")
  end
end
