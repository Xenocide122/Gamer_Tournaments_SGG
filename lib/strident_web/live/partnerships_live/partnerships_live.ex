defmodule StridentWeb.PartnershipsLive do
  @moduledoc false
  use StridentWeb, :live_view
  alias Strident.Accounts.UserNotifier
  alias Strident.Partnerships
  alias Strident.Partnerships.Partnership

  @impl true
  def mount(_params, _session, socket) do
    roles = Partnerships.list_partnership_roles()
    changeset = make_changeset()

    socket =
      socket
      |> assign(:page_title, "Partnerships")
      |> assign(
        :page_description,
        "Reach out to us for Stride partnership, sponsorship and tournament organizer opportunities."
      )
      |> assign(:roles, Enum.map(roles, &{&1.name, &1.id}))
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"partnership" => attrs},
        socket
      ) do
    changeset =
      attrs
      |> make_changeset()
      |> Map.put(:action, :validate)

    socket
    |> assign(:changeset, changeset)
    |> then(&{:noreply, &1})
  end

  def handle_event("add-new-social-media-urls", _attrs, socket) do
    social_media_urls =
      [
        "" | Ecto.Changeset.get_field(socket.assigns.changeset, :social_media_urls, [""])
      ]
      |> Enum.slide(0, -1)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_change(:social_media_urls, social_media_urls)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "create-partnership",
        %{"partnership" => attrs},
        socket
      ) do
    case Partnerships.create_partnership(attrs) do
      {:ok, partnership} ->
        UserNotifier.deliver_partnership_form_submission(partnership)

        socket
        |> put_flash(:info, "Thank you! We will be in touch.")
        |> assign(:changeset, make_changeset())
        |> then(&{:noreply, &1})

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> put_flash(:error, "Please correct any errors and resubmit.")
        |> assign(:changeset, changeset)
        |> then(&{:noreply, &1})

      {:error, _} ->
        socket
        |> put_flash(:error, "Your email appears to be invalid.")
        |> then(&{:noreply, &1})
    end
  end

  defp make_changeset(attrs \\ %{}) do
    %Partnership{
      social_media_urls: [""]
    }
    |> Partnerships.change_partnership(attrs)
  end
end
