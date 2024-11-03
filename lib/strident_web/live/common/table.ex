defmodule StridentWeb.Live.Common.Table do
  @moduledoc false
  use Phoenix.Component
  import StridentWeb.Common.SvgUtils

  def pagination(assigns) do
    ~H"""
    <div class="flex justify-between pt-4">
      <div id="previous-page" phx-click="previous-page" phx-target={@myself}>
        <.svg icon={:chevron_left} height="40" width="40" class="fill-primary" />
      </div>

      <div class="flex items-center justify-center">
        <%= for index <- Enum.map(1..@total_pages, &(&1)) do %>
          <div
            class="mr-4 cursor-pointer"
            phx-click="go-to-page"
            phx-target={@myself}
            phx-value-page={index}
          >
            <.svg
              icon={:x_circle}
              height="15"
              width="15"
              class={if(@current_page == index, do: "fill-primary", else: "fill-grey-light")}
            />
          </div>
        <% end %>
      </div>

      <div id="next-page" phx-click="next-page" phx-target={@myself}>
        <.svg icon={:chevron_right} height="40" width="40" class="fill-primary" />
      </div>
    </div>
    """
  end
end
