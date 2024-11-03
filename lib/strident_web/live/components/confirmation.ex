defmodule StridentWeb.Components.Confirmation do
  @moduledoc """
  Fullscreen confirmation component.


  The component consists of a "message" and 2 buttons, "confirm" and "cancel".

  This component has only 1 necessary assign:

    * `confirm_event` - This is the event that gets pushed to the server when the "confirm"
      button is pressed

  This component also accepts the following optional assigns:

    * `target` - This is used as the `phx-target` value, for when we want to push the
      confirmation events to a LiveComponent

    * `confirm_values` - This is a map that will get sent as the params with the "confirm" event.

    * `confirm_prompt` - This is the text to appear on the "confirm" button.

    * `cancel_prompt` - This is the text to appear on the "cancel" button.

    * `message` - This is the HTML to render for the message

  Almost all of these optional assigns will not respect being `nil`.

  For example, trying to set `cancel_prompt` to `nil` will result in `"Cancel"` instead.

  By convention, the confirmation component in the view/component HTML, is conditionally rendered
  using a `show_confirmation` assign, like this:

  ```
  <%= if @show_confirmation do %>
    <.live_component
      id="my-confirmation"
      module={StridentWeb.Components.Confirmation}
      confirm_event={@confirmation_confirm_event}
      message={@confirmation_message}
      confirm_prompt={@confirmation_confirm_prompt}
      cancel_prompt={@confirmation_cancel_prompt}
    />
  <% end %>
  ```

  Note here how the "confirmation"-related assigns in the view/component have the same name
  as the assigns in this component, except all with a `"confirmation_"` prefix.

  Finally, see `StridentWeb.LiveViewHelpers.close_confirmation/1` for a convenient way to close
  the confirmation component. This relies on developers following the convention described above.
  """
  use StridentWeb, :live_component

  @impl true
  def update(%{confirm_event: confirm_event} = assigns, socket) do
    target_attribute =
      assigns
      |> Map.take([:target])
      |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, "phx-#{key}", value) end)
      |> assigns_to_attributes()

    confirm_values = Map.get(assigns, :confirm_values) || %{}

    confirm_value_attributes =
      confirm_values
      |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, "phx-value-#{key}", value) end)
      |> assigns_to_attributes()

    cancel_prompt = Map.get(assigns, :cancel_prompt) || "Cancel"
    confirm_prompt = Map.get(assigns, :confirm_prompt) || "Confirm"
    message = Map.get(assigns, :message) || "Confirm"

    socket
    |> copy_parent_assigns(assigns)
    |> assign(%{
      target_attribute: target_attribute,
      message: message,
      cancel_prompt: cancel_prompt,
      confirm_prompt: confirm_prompt,
      confirm_event: confirm_event,
      confirm_value_attributes: confirm_value_attributes
    })
    |> then(&{:ok, &1})
  end
end
