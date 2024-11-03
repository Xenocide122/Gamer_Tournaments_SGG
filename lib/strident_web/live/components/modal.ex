defmodule StridentWeb.Components.Modal do
  @moduledoc false
  use Phoenix.Component
  import StridentWeb.Common.SvgUtils
  alias Phoenix.LiveView.JS

  def modal_wide(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:header, fn -> [] end)
      |> assign_new(:confirm, fn -> [] end)
      |> assign_new(:cancel, fn -> [] end)
      |> assign_rest(~w(id confirm cancel)a)

    ~H"""
    <.modal id={@id} modal_size="p-8 modal__dialog modal__dialog--medium">
      <div class="">
        <div class={
          "flex items-center #{if(Enum.empty?(@header), do: "justify-end", else: "justify-between")}"
        }>
          <%= render_slot(@header) %>
          <div class="flex justify-end" phx-click={hide_modal(@id)}>
            <.svg icon={:x} height="20" width="20" class="fill-primary" />
          </div>
        </div>
      </div>

      <div class="mb-10">
        <%= render_slot(@inner_block) %>
      </div>

      <div class="flex justify-between space-x-4">
        <%= for cancel <- @cancel do %>
          <%= render_slot(cancel) %>
        <% end %>

        <%= for confirm <- @confirm do %>
          <%= render_slot(confirm) %>
        <% end %>
      </div>
    </.modal>
    """
  end

  def modal_small(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:header, fn -> [] end)
      |> assign_new(:confirm, fn -> [] end)
      |> assign_new(:cancel, fn -> [] end)
      |> assign_rest(~w(id confirm cancel)a)

    ~H"""
    <.modal id={@id} modal_size="modal__dialog--small">
      <div class="px-4 pt-4 modal-header">
        <div class={
          "flex items-center #{if(Enum.empty?(@header), do: "justify-end", else: "justify-between")}"
        }>
          <%= render_slot(@header) %>
          <div class="flex justify-end" phx-click={hide_modal(@id)}>
            <.svg icon={:x} height="20" width="20" class="fill-primary" />
          </div>
        </div>
      </div>

      <div class="px-4 pt-2 modal-body">
        <%= render_slot(@inner_block) %>
      </div>

      <div class="flex justify-between p-4 modal-footer">
        <%= for cancel <- @cancel do %>
          <%= render_slot(cancel) %>
        <% end %>

        <%= for confirm <- @confirm do %>
          <%= render_slot(confirm) %>
        <% end %>
      </div>
    </.modal>
    """
  end

  def modal_medium(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:header, fn -> [] end)
      |> assign_new(:confirm, fn -> [] end)
      |> assign_new(:cancel, fn -> [] end)
      |> assign_rest(~w(id confirm cancel)a)

    ~H"""
    <.modal id={@id} modal_size="modal__dialog--medium">
      <div class="px-4 pt-4 modal-header">
        <div class="flex items-center justify-between">
          <%= render_slot(@header) %>
          <div class="flex justify-end" phx-click={hide_modal(@id)}>
            <.svg icon={:x} height="20" width="20" class="fill-grey-light" />
          </div>
        </div>
      </div>

      <div class="px-4 pt-2 modal-body">
        <%= render_slot(@inner_block) %>
      </div>

      <div class="flex justify-between p-4 modal-footer">
        <%= for cancel <- @cancel do %>
          <%= render_slot(cancel) %>
        <% end %>

        <%= for confirm <- @confirm do %>
          <%= render_slot(confirm) %>
        <% end %>
      </div>
    </.modal>
    """
  end

  def modal_large(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:header, fn -> [] end)
      |> assign_new(:confirm, fn -> [] end)
      |> assign_new(:cancel, fn -> [] end)
      |> assign_rest(~w(id confirm cancel)a)

    ~H"""
    <.modal id={@id}>
      <div class="px-4 pt-4 modal-header">
        <div class="flex items-center justify-between">
          <%= render_slot(@header) %>
          <div class="flex justify-end" phx-click={hide_modal(@id)}>
            <.svg icon={:x} height="5" width="5" class="fill-grey-light" />
          </div>
        </div>
      </div>

      <div class="px-4 pt-2 modal-body">
        <%= render_slot(@inner_block) %>
      </div>

      <div class="flex justify-between p-4 modal-footer">
        <%= for cancel <- @cancel do %>
          <%= render_slot(cancel) %>
        <% end %>

        <%= for confirm <- @confirm do %>
          <%= render_slot(confirm) %>
        <% end %>
      </div>
    </.modal>
    """
  end

  def modal(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:modal_size, fn -> "modal__dialog--medium" end)
      |> assign_new(:class, fn -> nil end)
      |> assign_new(:hide_callback, fn -> nil end)
      |> assign_new(:hide_callback_target, fn -> nil end)
      |> assign_rest(~w(id)a)

    ~H"""
    <div id={@id} class={if @show, do: "fade-in-scale", else: "hidden"}>
      <div class="fixed inset-0 z-10 overflow-y-auto">
        <div class="block min-h-screen px-4 text-center">
          <div
            class="fixed inset-0 transition-opacity bg-blackish bg-opacity-90"
            phx-key="escape"
            phx-window-keydown={if @hide_callback, do: @hide_callback, else: hide_modal(@id)}
            phx-target={@hide_callback_target}
            phx-value-id={@id}
          >
          </div>

          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>

          <div
            id={"modal-#{@id}-container"}
            class={["my-24 modal__dialog #{@modal_size}", @class]}
            phx-click-away={if @hide_callback, do: @hide_callback, else: hide_modal(@id)}
            phx-target={@hide_callback_target}
            phx-value-id={@id}
          >
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> js_exec("##{id}-confirm", "focus", [])
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.dispatch("click", to: "##{id} [data-modal-return]")
  end

  defp assign_rest(assigns, exclude) do
    assign(assigns, :rest, assigns_to_attributes(assigns, exclude))
  end

  @doc """
  Calls a wired up event listener to call a function with arguments.
      window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  """
  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end
end
