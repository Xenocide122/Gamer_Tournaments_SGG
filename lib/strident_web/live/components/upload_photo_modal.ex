defmodule StridentWeb.Components.UploadPhotoModal do
  @moduledoc false
  use StridentWeb, :live_component
  alias Strident.SimpleS3Upload
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <div class="hidden md:block">
      <.button
        id={"#{@id}-button"}
        button_type={:primary_ghost}
        class="mx-8 mt-24 rounded inner-glow"
        phx-click={show_modal("#{@id}-modal")}
      >
        <%= @upload_button_text %>
      </.button>

      <.modal_medium id={[@id, "-modal"]}>
        <:header>
          <h3>Upload new image</h3>
        </:header>

        <div id="upload-photos" class="mb-8 bg-blackish">
          <div :if={@inner_block}>
            <%= render_slot(@inner_block) %>
          </div>
          <.form
            id={[@id, "-form"]}
            for={to_form(%{}, as: :photo)}
            phx-change="validate"
            phx-submit="save"
            phx-target={@myself}
          >
            <div class="container" phx-drop-target={@uploads.photo.ref} phx-target={@myself}>
              <%= label(class: if(Enum.count(@uploads.photo.entries) > 0, do: "hidden")) do %>
                <%= live_file_input(@uploads.photo, class: "hidden") %>
                <div class="flex justify-center pt-4">
                  <div class="grid px-8 py-10 upload-box place-items-center">
                    <img class="w-20 mb-1 h-15" src="/images/file_group.png" />
                    <p class="mb-1">
                      Drag and Drop Your Photo
                    </p>

                    <div class="flex text-xs text-grey-light">
                      <p class="mr-1">
                        Or
                      </p>
                      <p class="mr-1 link clickable">
                        Select Photo
                      </p>
                      <p>
                        from your computer
                      </p>
                    </div>
                  </div>
                </div>
              <% end %>

              <div class="flex justify-center py-8">
                <div :for={entry <- @uploads.photo.entries}>
                  <div class="flex flex-col">
                    <div class="relative">
                      <.svg
                        icon={:x}
                        class="absolute z-10 fill-primary top-2 right-2"
                        height="20"
                        width="20"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        phx-target={@myself}
                      />

                      <.live_img_preview entry={entry} width={800} />
                    </div>

                    <div class="mt-2 progress-bar">
                      <div
                        class="progress-bar__fill"
                        style={"transform: translateX(-#{100 - entry.progress}%)"}
                      >
                      </div>
                    </div>
                  </div>

                  <p :for={error <- upload_errors(@uploads.photo, entry)} class="alert alert-danger">
                    <%= error_to_string(error) %>
                  </p>
                </div>
              </div>
            </div>
          </.form>

          <div class="flex justify-center gap-4">
            <.button
              id={"#{@id}-cancel-button"}
              button_type={:primary_ghost}
              class="uppercase rounded inner-glow"
              phx-click={hide_modal("#{@id}-modal")}
            >
              Cancel
            </.button>

            <.button
              id={"#{@id}-save-button"}
              form={"#{@id}-form"}
              type="submit"
              button_type={:primary}
              class="rounded"
              phx-click={JS.push("save", target: @myself) |> hide_modal("#{@id}-modal")}
            >
              Save
            </.button>
          </div>
        </div>
      </.modal_medium>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    %{
      id: id,
      upload_button_text: upload_button_text,
      update_function: update_function,
      aws_bucket_subfolder: aws_bucket_subfolder,
      parent_pid: parent_pid
    } = assigns

    socket
    |> copy_parent_assigns(assigns)
    |> assign(:id, id)
    |> assign(:upload_button_text, upload_button_text)
    |> assign(:update_function, update_function)
    |> assign(:aws_bucket_subfolder, aws_bucket_subfolder)
    |> assign(:parent_pid, parent_pid)
    |> assign(:inner_block, Map.get(assigns, :inner_block))
    |> allow_upload(:photo,
      accept: ~w(.png .jpg .jpeg),
      max_entries: 1,
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
  def handle_event("save", _params, socket) do
    Task.async(fn ->
      %{update_function: update_function, parent_pid: parent_pid} = socket.assigns
      send(parent_pid, :photo_upload_started)
      photos = get_photos_params(socket)

      case update_function.(photos, &consume_photos(socket, &1)) do
        {:ok, object} -> send(parent_pid, {:photo_upload_finished, object})
        {:error, reason} -> send(parent_pid, {:photo_upload_error, reason})
      end
    end)

    {:noreply, socket}
  end

  def consume_photos(socket, photo) do
    consume_uploaded_entries(socket, :photo, fn _meta, _entry -> {:ok, photo} end)
    {:ok, photo}
  end

  defp get_photos_params(socket) do
    case uploaded_entries(socket, :photo) do
      {[_ | _] = completed, []} ->
        %{aws_bucket_subfolder: aws_bucket_subfolder} = socket.assigns

        for entry <- completed,
            do: Enum.join([SimpleS3Upload.host(), aws_bucket_subfolder, s3_key(entry)], "/")

      {[], [_ | _] = _in_progress} ->
        :timer.sleep(1_000)
        get_photos_params(socket)
    end
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp s3_key(entry), do: "#{entry.uuid}.#{ext(entry)}"

  defp presign_entry(entry, socket) do
    %{uploads: uploads, aws_bucket_subfolder: aws_bucket_subfolder} = socket.assigns
    key = Enum.join([aws_bucket_subfolder, s3_key(entry)], "/")

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
    Enum.join([SimpleS3Upload.host(), photo_link], "/")
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
