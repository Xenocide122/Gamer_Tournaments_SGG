defmodule StridentWeb.Components.TournamentCardFormComponent do
  @moduledoc """
  LV to allow for the creation / editing of full width tournament cards
  """
  use StridentWeb, :live_component

  alias Strident.SimpleS3Upload
  alias Strident.Tournaments.TournamentsPageInfoCard

  @impl true
  def update(%{card: card} = assigns, socket) do
    changeset = TournamentsPageInfoCard.changeset(card)

    socket =
      socket
      |> assign(assigns)
      |> assign(:action, :edit)
      |> assign(:changeset, changeset)
      |> allow_upload(:background_image,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    changeset = TournamentsPageInfoCard.changeset(%TournamentsPageInfoCard{})

    socket =
      socket
      |> assign(assigns)
      |> assign(:action, :new)
      |> assign(card: nil)
      |> assign(:changeset, changeset)
      |> allow_upload(:background_image,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"tournaments_page_info_card" => card_params}, socket) do
    card =
      if is_nil(socket.assigns.card),
        do: %TournamentsPageInfoCard{},
        else: socket.assigns.card

    changeset =
      card
      |> TournamentsPageInfoCard.changeset(card_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"tournaments_page_info_card" => card_params}, socket) do
    save_card(socket, card_params)
  end

  def handle_event("remove-photo", %{"ref" => ref}, socket) do
    socket
    |> cancel_upload(:background_image, ref)
    |> then(&{:noreply, &1})
  end

  defp save_card(%{assigns: %{action: :edit}} = socket, card_params) do
    card_params =
      card_params
      |> maybe_add_image_url(socket)

    case TournamentsPageInfoCard.update_card(socket.assigns.card, card_params) do
      {:ok, card} ->
        consume_photos(socket, card)

        {:noreply,
         socket
         |> put_flash(:info, "Card updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_card(%{assigns: %{action: :new}} = socket, card_params) do
    card_params =
      card_params
      |> maybe_add_image_url(socket)

    case TournamentsPageInfoCard.create_card(card_params) do
      {:ok, card} ->
        consume_photos(socket, card)

        {:noreply,
         socket
         |> put_flash(:info, "Card updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp maybe_add_image_url(attrs, socket) do
    case get_img_params(socket, :background_image) do
      [%{url: url}] ->
        Map.put(attrs, "background_image_url", url)

      _ ->
        attrs
    end
  end

  defp get_img_params(socket, img) do
    {completed, []} = uploaded_entries(socket, img)
    base_aws_key = "tournamentinfocards/"

    for entry <- completed do
      %{url: SimpleS3Upload.host() <> "/" <> base_aws_key <> s3_key(entry)}
    end
  end

  def consume_photos(socket, %TournamentsPageInfoCard{} = card) do
    consume_uploaded_entries(socket, :background_image, fn _meta, _entry -> {:ok, card} end)
    {:ok, card}
  end

  defp presign_entry(entry, socket) do
    base_aws_key = "tournamentinfocards/"
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
end
