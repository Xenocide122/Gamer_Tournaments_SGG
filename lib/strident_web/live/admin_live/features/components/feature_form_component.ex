defmodule StridentWeb.AdminLive.Features.Components.FeatureFormComponent do
  @moduledoc """
  LV to allow for the creation / editing of popups displayed to alert users about new features
  """
  use StridentWeb, :live_component
  alias Strident.Features.Feature
  alias Strident.SimpleS3Upload

  @impl true
  def update(%{feature: %Feature{}} = assigns, socket) do
    %{feature: feature, return_to: return_to} = assigns
    changeset = Feature.changeset(feature)

    socket =
      socket
      |> copy_parent_assigns(assigns)
      |> assign(:action, :edit)
      |> assign(:feature, feature)
      |> assign(:return_to, return_to)
      |> assign(:changeset, changeset)
      |> assign(:tags_option, Ecto.Enum.values(Feature, :tags))
      |> assign(:selected_tags, Enum.map(feature.tags, &Atom.to_string/1))
      |> assign(:search_results, [])
      |> allow_upload(:image,
        accept: ~w(.png .jpg .jpeg),
        max_entries: 1,
        external: &presign_entry/2
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    %{return_to: return_to} = assigns
    changeset = Feature.changeset(%Feature{})

    socket =
      socket
      |> copy_parent_assigns(assigns)
      |> assign(:action, :new)
      |> assign(:return_to, return_to)
      |> assign(:feature, %Feature{})
      |> assign(:changeset, changeset)
      |> assign(:tags_option, Ecto.Enum.values(Feature, :tags))
      |> assign(:selected_tags, [])
      |> assign(:search_results, [])
      |> allow_upload(:image,
        accept: ~w(.png .jpg .jpeg .svg),
        max_entries: 1,
        external: &presign_entry/2
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"feature" => feature_params}, socket) do
    %{feature: feature} = socket.assigns

    changeset =
      feature
      |> Feature.changeset(feature_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("searched_tags", %{"feature" => %{"searched_tag" => value}}, socket)
      when byte_size(value) >= 3 do
    %{tags_option: tags, selected_tags: selected_tags} = socket.assigns

    search_results =
      tags
      |> Enum.reject(&(Atom.to_string(&1) in selected_tags))
      |> Enum.filter(&String.contains?(Atom.to_string(&1), value))

    socket
    |> assign(:search_results, search_results)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("searched_tags", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select-tag", %{"tag" => tag}, socket) do
    socket
    |> update(:selected_tags, &Enum.reverse([tag | &1]))
    |> assign(:search_results, [])
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("remove-tag", %{"tag" => tag}, socket) do
    socket
    |> update(:selected_tags, &(&1 -- [tag]))
    |> then(&{:noreply, &1})
  end

  def handle_event("save", %{"feature" => params}, socket) do
    socket
    |> save(params)
    |> then(&{:noreply, &1})
  end

  def handle_event("remove-photo", %{"ref" => ref}, socket) do
    socket
    |> cancel_upload(:image, ref)
    |> then(&{:noreply, &1})
  end

  defp save(%{assigns: %{action: :edit}} = socket, params) do
    %{feature: feature, return_to: return_to} = socket.assigns
    params = maybe_add_image_url(params, socket)

    case Feature.update(feature, params) do
      {:ok, feature} ->
        consume_photos(socket, feature)

        socket
        |> put_flash(:info, "Feature updated successfully")
        |> push_redirect(to: return_to)

      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, :changeset, changeset)
    end
  end

  defp save(%{assigns: %{action: :new}} = socket, params) do
    %{return_to: return_to} = socket.assigns
    params = maybe_add_image_url(params, socket)

    case Feature.create(params) do
      {:ok, feature} ->
        consume_photos(socket, feature)

        socket
        |> put_flash(:info, "Popup updated successfully")
        |> push_redirect(to: return_to)

      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, :changeset, changeset)
    end
  end

  defp maybe_add_image_url(attrs, socket) do
    case get_img_params(socket, :image) do
      [%{url: url}] ->
        Map.put(attrs, "image_url", url)

      _ ->
        attrs
    end
  end

  defp get_img_params(socket, img) do
    {completed, []} = uploaded_entries(socket, img)
    base_aws_key = "newfeature/"

    for entry <- completed do
      %{url: SimpleS3Upload.host() <> "/" <> base_aws_key <> s3_key(entry)}
    end
  end

  def consume_photos(socket, %Feature{} = feature) do
    consume_uploaded_entries(socket, :image, fn _meta, _entry -> {:ok, feature} end)
    {:ok, feature}
  end

  defp presign_entry(entry, socket) do
    base_aws_key = "newfeature/"
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
