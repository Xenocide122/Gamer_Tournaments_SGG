defmodule StridentWeb.Components.Flash do
  @moduledoc false
  import Phoenix.Component

  @default_classes "top-28 z-50 fixed w-full"

  def flash(%{myself: _, flash: %{"info" => _}} = assigns) do
    assigns = set_assigns(assigns)

    ~H"""
    <div
      id={"#{@id}"}
      class={"#{@class} #{@default_classes}"}
      phx-hook="FlashInfo"
      data-lifespan={"#{@lifespan_info}"}
    >
      <.info_from_component class={@class} extra={@extra} flash={@flash} myself={@myself} />
    </div>
    """
  end

  def flash(%{myself: _, flash: %{"error" => _}} = assigns) do
    assigns = set_assigns(assigns)

    ~H"""
    <div
      id={"#{@id}"}
      class={"#{@class} #{@default_classes}"}
      phx-hook="FlashError"
      data-lifespan={"#{@lifespan_error}"}
    >
      <.error_from_component class={@class} extra={@extra} flash={@flash} myself={@myself} />
    </div>
    """
  end

  def flash(%{flash: %{"info" => _}} = assigns) do
    assigns = set_assigns(assigns)

    ~H"""
    <div
      id={"#{@id}"}
      class={"#{@class} #{@default_classes}"}
      phx-hook="FlashInfo"
      data-lifespan={"#{@lifespan_info}"}
    >
      <.info class={@class} extra={@extra} flash={@flash} />
    </div>
    """
  end

  def flash(%{flash: %{"error" => _}} = assigns) do
    assigns = set_assigns(assigns)

    ~H"""
    <div
      id={"#{@id}"}
      class={"#{@class} #{@default_classes}"}
      phx-hook="FlashError"
      data-lifespan={"#{@lifespan_error}"}
    >
      <.error class={@class} extra={@extra} flash={@flash} />
    </div>
    """
  end

  def flash(assigns) do
    ~H"""

    """
  end

  def error(assigns) do
    ~H"""
    <p
      class="leading-7 cursor-pointer alert alert-danger"
      role="alert"
      phx-click="lv:clear-flash"
      {@extra}
      phx-value-key="error"
    >
      <%= live_flash(@flash, :error) %>
      <span class="float-right">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="30"
          height="30"
          viewBox="0 0 24 24"
          fill="currentColor"
        >
          <path d={StridentWeb.Common.SvgUtils.path(:close)}></path>
        </svg>
      </span>
    </p>
    """
  end

  def error_from_component(assigns) do
    ~H"""
    <p
      class="leading-7 cursor-pointer alert alert-danger"
      role="alert"
      phx-click="lv:clear-flash"
      phx-target={@myself}
      {@extra}
      phx-value-key="error"
    >
      <%= live_flash(@flash, :error) %>
      <span class="float-right">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="30"
          height="30"
          viewBox="0 0 24 24"
          fill="currentColor"
        >
          <path d={StridentWeb.Common.SvgUtils.path(:close)}></path>
        </svg>
      </span>
    </p>
    """
  end

  def info(assigns) do
    ~H"""
    <p
      class="leading-7 cursor-pointer alert alert-info"
      role="alert"
      phx-click="lv:clear-flash"
      {@extra}
      phx-value-key="info"
    >
      <%= live_flash(@flash, :info) %>
      <span class="float-right">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="30"
          height="30"
          viewBox="0 0 24 24"
          fill="currentColor"
        >
          <path d={StridentWeb.Common.SvgUtils.path(:close)}></path>
        </svg>
      </span>
    </p>
    """
  end

  def info_from_component(assigns) do
    ~H"""
    <p
      class="leading-7 cursor-pointer alert alert-info"
      role="alert"
      phx-click="lv:clear-flash"
      phx-target={@myself}
      {@extra}
      phx-value-key="info"
    >
      <%= live_flash(@flash, :info) %>
      <span class="float-right">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="30"
          height="30"
          viewBox="0 0 24 24"
          fill="currentColor"
        >
          <path d={StridentWeb.Common.SvgUtils.path(:close)}></path>
        </svg>
      </span>
    </p>
    """
  end

  @doc """
  By default we assing 3s before clearing flash
  """
  @spec set_assigns(map()) :: map()
  def set_assigns(assigns) do
    extra = assigns_to_attributes(assigns, [:id, :class, :flash])

    assigns
    |> Map.put_new(:id, "flash-component")
    |> Map.put_new(:class, [])
    |> Map.put_new(:lifespan_info, 10_000)
    |> Map.put_new(:lifespan_error, 10_000)
    |> Map.put(:extra, extra)
    |> Map.put(:default_classes, @default_classes)
  end
end
