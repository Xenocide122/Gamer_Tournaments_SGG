defmodule StridentWeb.NotificationLive.Components.Card do
  @moduledoc false
  use Phoenix.Component
  import StridentWeb.Common.SvgUtils
  import StridentWeb.DeadViews.Button
  import StridentWeb.Components.Containers
  alias Phoenix.LiveView.JS

  attr(:notification_id, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:class, :string, default: "")
  attr(:inner_class, :string, default: "")
  attr(:action_url, :any, default: nil)

  def notification_card(assigns) do
    ~H"""
    <.notification_card_template
      notification_id={@notification_id}
      icon={@icon}
      title={@title}
      body={@body}
      class={@class}
      inner_class={@inner_class}
      action_url={@action_url}
    >
      <:button>
        <.button
          :if={@action_url}
          id={"view-button-#{@notification_id}"}
          button_type={:primary_ghost}
          class="inner-glow"
          phx-click={
            JS.push("click-on-notification", value: %{id: @notification_id})
            |> JS.navigate(@action_url)
          }
        >
          View
        </.button>
      </:button>
    </.notification_card_template>
    """
  end

  attr(:notification_id, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:class, :string, default: "")
  attr(:inner_class, :string, default: "")
  attr(:action_url, :any, default: nil)

  def notification_badge(assigns) do
    ~H"""
    <div
      :if={!!@action_url}
      phx-click={
        JS.push("click-on-notification", value: %{id: @notification_id})
        |> JS.navigate(@action_url)
      }
      class="cursor-pointer"
    >
      <.notification_card_template
        notification_id={"badge-#{@notification_id}"}
        icon={@icon}
        title={@title}
        body={@body}
        class={@class}
        inner_class={@inner_class}
      />
    </div>

    <.notification_card_template
      :if={!@action_url}
      notification_id={"badge-#{@notification_id}"}
      icon={@icon}
      title={@title}
      body={@body}
      class={@class}
      inner_class={@inner_class}
    />
    """
  end

  attr(:notification_id, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:class, :string, default: "")
  attr(:inner_class, :string, default: "")
  attr(:action_url, :any, default: nil)
  slot(:button, required: false)

  defp notification_card_template(assigns) do
    ~H"""
    <.card
      id={@notification_id}
      colored={true}
      class={Enum.join(["rounded-2xl mb-4", @class], " ")}
      inner_class={Enum.join(["rounded-2xl", @inner_class], " ")}
    >
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <.svg icon={@icon} width="30" height="30" class="w-16 h-16 fill-primary" />
          <div class="flex flex-col mx-3 text-sm">
            <div class="font-medium leading-none text-white">
              <%= @title %>
            </div>

            <p class="mt-1 text-xs leading-none text-grey-light">
              <%= @body %>
            </p>
          </div>
        </div>
        <%= render_slot(@button) %>
      </div>
    </.card>
    """
  end
end
