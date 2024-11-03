defmodule StridentWeb.DeadViews.Spinner do
  @moduledoc false
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  slot(:inner_block, required: true)
  attr(:svg_size, :integer, default: 180)
  attr(:radius, :integer, default: 90)
  attr(:dash_array, :integer, default: 135)
  attr(:message, :string, default: "")

  def fullscreen_spinner(assigns) do
    class = "fullscreen-spinner"

    inner_class =
      "fixed top-0 bottom-0 left-0 right-0 z-50 flex flex-col items-center justify-center w-full h-screen overflow-hidden bg-blackish opacity-75"

    message_class = "w-full mt-6 text-2xl text-center text-primary"
    fullscreen_assigns = %{class: class, inner_class: inner_class, message_class: message_class}

    assigns
    |> Map.merge(fullscreen_assigns)
    |> spinner()
  end

  slot(:inner_block, required: true)
  attr(:class, :string, default: nil)
  attr(:spinner_class, :string, default: "hidden")
  attr(:message_class, :string, default: "")
  attr(:inner_class, :string, default: nil)
  attr(:spinner_id, :string, default: "#spinner")
  attr(:svg_size, :integer, default: 180)
  attr(:radius, :integer, default: 90)
  attr(:dash_array, :integer, default: 135)
  attr(:message, :string, default: "")

  def spinner(assigns) do
    ~H"""
    <div
      js-trigger-show-spinner
      js-action-show-spinner={JS.show(to: @spinner_id)}
      js-trigger-close-spinner
      js-action-close-spinner={JS.hide(to: @spinner_id)}
      class={@class}
    >
      <%= render_slot(@inner_block) %>

      <div id={@spinner_id} class={@spinner_class}>
        <div class={@inner_class}>
          <svg
            width={@svg_size}
            height={@svg_size}
            fill="none"
            stroke="currentColor"
            stroke-width="5"
            class="items-center mr-3 animate-spin text-primary"
          >
            <circle cx={@radius} cy={@radius} r={@radius} stroke-dasharray={@dash_array}></circle>
          </svg>
        </div>
        <div :if={@message} class={@message_class}>
          <%= @message %>
        </div>
      </div>
    </div>
    """
  end
end
