defmodule StridentWeb.Components.QrCodeComponent do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal_small id={@id}>
        <:header>
          <h3 class="px-4 pt-2">QR Code</h3>
        </:header>
        <div class="flex justify-center pt-2">
          <hr class="border-t-0.5 border-grey-light" width="95%" />
        </div>

        <div class="flex justify-center px-8 pt-4">
          <div
            class="border inner-glow border-primary"
            phx-hook="QrCode"
            id="qr-code"
            data-page-link={@page_link}
          >
          </div>
        </div>
      </.modal_small>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{id: id, page_link: page_link} = assigns

    socket
    |> assign(:id, id)
    |> assign(:page_link, page_link)
    |> then(&{:ok, &1})
  end
end
