defmodule StridentWeb.Components.Table do
  @moduledoc """
  This are Stride table components.
  """
  use Phoenix.Component

  # Slots

  slot(:col, doc: "Columns with column labels") do
    attr(:label, :string, required: true, doc: "Column label")
    attr(:class, :string, required: false, doc: "Class for col")
  end

  attr(:id, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:thead_class, :string, default: nil)
  attr(:tbody_class, :string, default: nil)
  attr(:rows, :list, default: [])
  attr(:row_id, :any, default: false)
  attr(:height, :integer, default: nil)
  attr(:width, :integer, default: nil)
  attr(:tr_class, :any, default: &__MODULE__.tr_class/1)

  def table(assigns) do
    ~H"""
    <table class={["w-full table-auto", @class]} height={@height} width={@width}>
      <thead class={["bg-blackish", @thead_class]}>
        <tr>
          <th :for={col <- @col} class="px-2 py-1 text-xs text-left text-grey-light">
            <span class="lg:pl-2"><%= col.label %></span>
          </th>
        </tr>
      </thead>

      <tbody id={@id} phx-update="replace" class={@tbody_class}>
        <%= for row <- @rows do %>
          <tr
            id={@row_id && @row_id.(row)}
            class={["p-10 text-sm rounded bg-blackish odd:bg-grey-medium", @tr_class.(row)]}
          >
            <%= for col <- @col do %>
              <td class={["text-sm p-2", col[:class]]}>
                <div class="flex items-center space-x-3 lg:pl-2">
                  <%= render_slot(col, row) %>
                </div>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def tr_class(_row), do: nil
end
