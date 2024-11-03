defmodule StridentWeb.Components.UrlQrCodeComponent do
  # TODO: DELETE IF WE DO NOT NEED IT
  @moduledoc """
  Displays a normal link with option to view as QR code.
  """
  # use Phoenix.Component

  # use StridentWeb, :live_component
  # alias Strident.UrlGeneration
  # alias StridentWeb.Components.QrCodeComponent
  # alias StridentWeb.Components.Modal

  # def display(%{absolute_path: absolute_path}) when is_binary(absolute_path) do
  #   assigns = %{absolute_path: absolute_path}

  #   ~H"""
  #   <span class="mb-0 text-white">
  #     <%= @absolute_path %>
  #     <p class="py-2 uppercase text-primary cursor-pointer" phx-click={Modal.show_modal("url-qr-code")}>
  #       Show QR
  #     </p>
  #     <.live_component id="url-qr-code" module={QrCodeComponent} page_link={@absolute_path} />
  #   </span>
  #   """
  # end

  # def display(%{relative_path: relative_path}) when is_binary(relative_path) do
  #   absolute_path = UrlGeneration.absolute_path(relative_path)
  #   display(%{absolute_path: absolute_path})
  # end
end
