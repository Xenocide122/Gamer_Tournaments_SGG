defmodule StridentWeb.Live.Components.TimezoneModalComponent do
  @moduledoc false
  use StridentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       checked: true,
       trigger_action: false,
       error: false,
       default_timezone: :stored,
       check_timezone: true,
       form: to_form(%{}, as: :timezone)
     )}
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> copy_parent_assigns(assigns)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("continue", params, socket) when %{} == params do
    socket =
      socket
      |> assign(:error, true)

    {:noreply, socket}
  end

  def handle_event("continue", %{"timezone" => %{"default_timezone" => ""}}, socket) do
    socket =
      socket
      |> assign(:error, true)

    {:noreply, socket}
  end

  def handle_event(
        "continue",
        %{"timezone" => %{"default_timezone" => default_timezone, "dont_ask" => dont_ask}},
        socket
      ) do
    socket =
      socket
      |> assign(trigger_action: true)
      |> assign(default_timezone: default_timezone)
      |> assign(check_timezone: reverse_boolean(dont_ask))

    {:noreply, socket}
  end

  def handle_event("change", %{"timezone" => %{"check_timezone" => checked}}, socket) do
    {:noreply, assign(socket, :checked, checked)}
  end

  defp reverse_boolean("false"), do: true
  defp reverse_boolean("true"), do: false

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!!@timezone and !!@current_user} class="modal__overlay">
        <div class="modal__frame">
          <div class="modal__backdrop"></div>
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          <div class="my-24 modal__dialog modal__dialog--medium">
            <.form
              :let={f}
              for={@form}
              phx-target={@myself}
              phx-change="change"
              phx-submit="continue"
              phx-trigger-action={@trigger_action}
              action={Routes.user_timezone_path(@socket, :update)}
            >
              <%= hidden_input(f, :user_return_to, value: @user_return_to) %>
              <%= hidden_input(f, :default_timezone, value: @default_timezone) %>
              <%= hidden_input(f, :check_timezone, value: @check_timezone) %>
              <.card>
                <div class="mb-8">
                  <h3 class="">Timezone Confirmation</h3>
                  <p>
                    We have noticed that the timezone we have stored for you does not match your location, what would you like us to do?
                  </p>
                </div>
                <div class="flex items-center mb-4 grilla-radio">
                  <%= label(class: "font-light mb-0") do %>
                    <%= radio_button(f, :default_timezone, "location_update", class: "mr-4") %>
                    <%= "Use my location timezone #{@timezone} and update my stored timezone" %>
                  <% end %>
                </div>
                <div class="flex items-center mb-4 grilla-radio">
                  <%= label(class: "font-light mb-0") do %>
                    <%= radio_button(f, :default_timezone, "location", class: "mr-4") %>
                    <%= "Use my location #{@timezone} and don't update my stored timezone #{@current_user.timezone}" %>
                  <% end %>
                </div>
                <div class="flex items-center mb-4 grilla-radio">
                  <%= label(class: "font-light mb-0") do %>
                    <%= radio_button(f, :default_timezone, "stored", class: "mr-4", checked: true) %>
                    <%= "Use my stored timezone #{@current_user.timezone}" %>
                  <% end %>
                </div>

                <div class="flex justify-end mt-8 gap-x-4">
                  <div class="flex items-center mr-4">
                    <div class="mr-2">
                      <p>Don't ask me again</p>
                    </div>
                    <div class="">
                      <%= checkbox(f, :dont_ask,
                        value: @checked,
                        class:
                          "w-5 h-5 border-gray-300 rounded focus:ring-primary focus:ring-offset-0 text-primary checked:bg-gray-800 checked:border-primary"
                      ) %>
                    </div>
                  </div>
                  <div class="">
                    <%= submit("Continue",
                      class: "btn btn--primary-ghost",
                      phx_disable_with: "Continue"
                    ) %>
                  </div>
                </div>
              </.card>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
