defmodule StridentWeb.Components.Form do
  use Phoenix.Component
  import Phoenix.HTML.Form
  import StridentWeb.ErrorHelpers
  alias Strident.Extension.DateTime
  alias Strident.Extension.NaiveDateTime

  @moduledoc """
  Form components

  Required props for all components:
  - `form`, Phoenix.Form.t()
  - `field`, :atom

  Optional props for all components:
  - `class`, :string

  Optional props for labels:
  - `label`, :string
  """

  def form_label(assigns) do
    assigns = assign_label_defaults(assigns)

    ~H"""
    <%= label @form, @field, class: @class do %>
      <%= @label %>
    <% end %>
    """
  end

  def form_text_input(assigns) do
    assigns = assign_input_defaults(assigns)

    ~H"""
    <%= text_input(@form, @field, [
      {:class, @class_override},
      {:phx_feedback_for, input_name(@form, @field)} | @input_attributes
    ]) %>
    """
  end

  def form_number_input(assigns) do
    assigns = assign_input_defaults(assigns)

    ~H"""
    <%= number_input(@form, @field, [
      {:class, @class_override},
      {:phx_feedback_for, input_name(@form, @field)} | @input_attributes
    ]) %>
    """
  end

  def form_email_input(assigns) do
    assigns = assign_input_defaults(assigns)

    ~H"""
    <%= email_input(@form, @field, [
      {:class, @class_override},
      {:phx_feedback_for, input_name(@form, @field)} | @input_attributes
    ]) %>
    """
  end

  def form_password_input(assigns) do
    assigns = assign_input_defaults(assigns)

    ~H"""
    <div class="relative" x-data="passwordInput">
      <%= password_input(@form, @field, [
        {:class, @class_override},
        {:phx_feedback_for, input_name(@form, @field)},
        {"x-bind", "input"} | @input_attributes
      ]) %>
      <div
        class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm leading-5 cursor-pointer password-svg-wrapper"
        x-bind="button"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="22"
          height="22"
          viewBox="0 -16 544 544"
          fill="currentColor"
          class="password-svg-show"
        >
          <path d={StridentWeb.Common.SvgUtils.path(:show_password)}></path>
        </svg>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="22"
          height="22"
          viewBox="0 -16 544 544"
          fill="currentColor"
          class="password-svg-hide"
        >
          <path d={StridentWeb.Common.SvgUtils.path(:hide_password)}></path>
        </svg>
      </div>
    </div>
    """
  end

  def form_textarea(assigns) do
    assigns = assign_input_defaults(assigns)

    ~H"""
    <%= textarea(@form, @field, [
      {:class, @class_override},
      {:phx_feedback_for, input_name(@form, @field)} | @input_attributes
    ]) %>
    """
  end

  def form_select(assigns) do
    assigns = assign_input_defaults(assigns)

    ~H"""
    <%= select(@form, @field, @values, [
      {:class, @class_override},
      {:phx_feedback_for, input_name(@form, @field)} | @input_attributes
    ]) %>
    """
  end

  @doc """
  A browser-timezone aware datetime picker using Flatpickr.

  We have to update the NaiveDateTime to an explicitly UTC DateTime
  so that Flatpickr can transform to local timezone. If left as naive,
  Flatpickr would assume the given datetime is already in local time,
  which creates terrible problems.

  ## Optional fields
  notime: prevent selecting time, only allow date selection
  mode: single, multiple or range; defaults to single
  inline: render date picker inline rather than as a popup when input is selected
  """
  def form_datetime_local_input(assigns) do
    assigns = assign_input_defaults(assigns)
    notime = !!Map.get(assigns, :notime)
    raw_current_value = input_value(assigns.form, assigns.field)

    current_value =
      case raw_current_value do
        nil ->
          if notime, do: Date.utc_today(), else: NaiveDateTime.utc_now()

        string when is_binary(string) ->
          if notime do
            case Date.from_iso8601(string) do
              {:ok, result} -> result
              {:error, _} -> Date.utc_today()
            end
          else
            case NaiveDateTime.from_iso8601(string) do
              {:ok, result} -> result
              {:error, _} -> NaiveDateTime.utc_now()
            end
          end

        other ->
          other
      end

    timezone = Map.get(assigns, :timezone) || "Etc/UTC"

    local_current_value =
      if notime,
        do: current_value,
        else: current_value |> DateTime.from_naive!("Etc/UTC") |> DateTime.shift_zone!(timezone)

    timezone_offset_seconds =
      if notime,
        do: 0,
        else: local_current_value |> DateTime.to_naive() |> Timex.diff(current_value, :seconds)

    assigns = Map.put(assigns, :timezone_offset_seconds, timezone_offset_seconds)

    ~H"""
    <%= Phoenix.HTML.Tag.content_tag :div, [id: "datetime-local-input-content-tage-#{input_name(@form, @field)}", class: "control", phx_update: "ignore"] do %>
      <%= text_input(@form, @field, [
        {:class, @class_override},
        {:placeholder, "Select date and time"},
        {:phx_feedback_for, input_name(@form, @field)},
        {:phx_hook, "Flatpickr"},
        {"data-timezone", @timezone},
        {"data-timezone_offset_seconds", @timezone_offset_seconds}
        | @input_attributes
      ]) %>
    <% end %>
    """
  end

  def form_feedback(assigns) do
    assigns = Map.put_new(assigns, :opts, [])

    ~H"""
    <%= error_tag(@form, @field, @opts) %>
    """
  end

  defp ensure_class_assigned(assigns) do
    assign_new(assigns, :class, fn -> nil end)
  end

  defp assign_input_class_override(%{class: class} = assigns) do
    assign(assigns, :class_override, "form-input #{error_class(assigns)} #{class}")
  end

  defp assign_label_defaults(%{field: field} = assigns) do
    assigns
    |> ensure_class_assigned()
    |> assign_new(:label, fn -> humanize(field) end)
  end

  defp assign_input_defaults(assigns) do
    input_attributes =
      assigns_to_attributes(assigns, [
        :form,
        :field,
        :label,
        :class,
        :values,
        :timezone,
        :phx_debounce
      ])

    assigns
    |> ensure_class_assigned()
    |> assign_input_class_override()
    |> assign_new(:input_attributes, fn -> input_attributes end)
    |> assign_new(:timezone, fn -> nil end)
  end

  defp error_class(%{form: %{errors: errors}, field: field}) when is_list(errors) do
    if List.keyfind(errors, field, 0), do: "form-input--error"
  end

  defp error_class(_), do: nil
end
