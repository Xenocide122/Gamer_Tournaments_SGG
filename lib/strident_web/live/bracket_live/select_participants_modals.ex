defmodule StridentWeb.BracketLive.SelectParticipantsModals do
  @moduledoc false
  use StridentWeb, :component

  attr(:locale, :any, required: true)
  attr(:timezone, :any, required: true)
  attr(:show, :boolean, required: true)
  attr(:target, :any, required: true)
  attr(:hide_callback, :any, required: true)
  attr(:search_term, :string, required: true)
  attr(:unseeded_only, :boolean, required: true)
  attr(:unlocked_only, :boolean, required: true)
  attr(:selected_ids, :list, required: true)
  attr(:seeded_tps, :list, required: true)
  attr(:unseeded_tps, :list, required: true)

  def unseeded_participants_modal(assigns) do
    ~H"""
    <div>
      <.modal
        :if={@show}
        id="participants-modal"
        show={@show}
        hide_callback={@hide_callback}
        hide_callback_target={@target}
        class="px-4 py-6 gap-y-6"
      >
        <h3 class="mb-6">
          Add Participants
        </h3>
        <div id="participants-modal-controls" class="mb-6 md:flex md:items-center gap-x-6">
          <.form
            :let={f}
            for={to_form(%{}, as: :participants_modal_search)}
            phx-change="search-unseeded-participants"
            phx-target={@target}
            class="flex items-center gap-x-4"
          >
            <div class="relative flex items-center">
              <.form_text_input
                id="search-unseeded-participants-input"
                form={f}
                field={:search_term}
                value={@search_term}
                phx-debounce={100}
                class="w-64 px-0 border-2 rounded-md bg-blackish"
                placeholder="Search"
              />
              <.svg icon={:search} width="24" height="24" class="absolute right-0 fill-grey-light" />
            </div>
          </.form>
          <div id="participants-modal-checkboxes">
            <.form
              :let={f}
              for={to_form(%{}, as: :participants_modal_filters)}
              phx-change="customize-participants-modal-filters"
              phx-target={@target}
              class="flex items-center gap-x-4"
            >
              <.checkbox
                form={f}
                field_name={:unseeded_only}
                checked={@unseeded_only}
                label="Show only unseeded"
                label_class="mb-0 ml-6"
                id="customize-participants-modal-filters-checkbox"
              />
              <.checkbox
                form={f}
                field_name={:unlocked_only}
                checked={@unlocked_only}
                label="Show only unlocked"
                label_class="mb-0 ml-6"
                id="customize-participants-modal-filters-checkbox-unlocked"
              />
            </.form>
            <.form
              :let={f}
              for={to_form(%{}, as: :select_all_unseeded_participants)}
              phx-change="toggle-all-unseeded-participant-selected"
              phx-target={@target}
              class="flex items-center gap-x-4"
            >
              <.checkbox
                form={f}
                field_name={:selected}
                checked={Enum.count(@selected_ids) == Enum.count(@unseeded_tps)}
                label="(De)-select all"
                label_class="text-primary mb-0 ml-6"
                id="select_all_unseeded_participants"
              />
            </.form>
          </div>
        </div>
        <div id="unseeded-participants-selector" class="mb-6 overflow-y-scroll max-h-80">
          <.table
            id="participants-modal-list"
            rows={
              build_rows(@unseeded_only, @unlocked_only, @unseeded_tps, @seeded_tps, @search_term)
            }
            row_id={&"participants-modal-list-row-#{&1.id}"}
            class="border-collapse"
            tr_class={fn tp -> if tp.seed_index, do: "opacity-50", else: nil end}
          >
            <:col :let={tp} label="Name">
              <div :if={is_nil(tp.seed_index)} class="flex items-center">
                <.form
                  :let={f}
                  id={"select_unseeded_participants-form-#{tp.id}"}
                  for={to_form(%{}, as: :select_unseeded_participants)}
                  phx-change="toggle-unseeded-participant-selected"
                  phx-target={@target}
                  class="flex items-center gap-x-4"
                >
                  <.checkbox
                    form={f}
                    field_name={:selected}
                    checked={tp.id in @selected_ids}
                    hidden_values={%{id: tp.id}}
                    label={tp.name}
                    label_class="text-primary mb-0 ml-6"
                    id={"select_unseeded_participants-#{tp.id}"}
                  />
                </.form>
              </div>
              <div :if={tp.seed_index} class="flex items-center">
                <%= tp.name %>
              </div>
            </:col>
            <:col :let={tp} label="Email"><%= tp.email %></:col>
            <:col :let={tp} label="Creation Date">
              <.localised_datetime
                datetime={tp.inserted_at}
                timezone={@timezone}
                locale={@locale}
                type={:date}
              />
            </:col>
            <:col :let={tp} label="Seed">
              <div class="text-primary">
                <%= tp.seed_index %>
              </div>
            </:col>
          </.table>
        </div>

        <div class="flex justify-between">
          <.button
            type="button"
            button_type={:primary_ghost}
            id="participants-modal-cancel-button"
            phx-click="hide-participants-modal"
            phx-target={@target}
            class="text-primary"
          >
            &lt; Cancel
          </.button>
          <div class="text-grey-light">
            <%= Enum.count(@selected_ids) %> selected / <%= Enum.count(@unseeded_tps) %> available
          </div>
          <.button
            type="button"
            button_type={:primary}
            id="participants-modal-confirm-button"
            phx-click="add-selected-unseeded-participants-to-seeds"
            phx-target={@target}
          >
            Add To Seeds
          </.button>
        </div>
      </.modal>
    </div>
    """
  end

  attr(:locale, :any, required: true)
  attr(:timezone, :any, required: true)
  attr(:show, :boolean, required: true)
  attr(:target, :any, required: true)
  attr(:hide_callback, :any, required: true)
  attr(:search_term, :string, required: true)
  attr(:unseeded_only, :boolean, required: true)
  attr(:unlocked_only, :boolean, required: true)
  attr(:selected_ids, :list, required: true)
  attr(:seeded_tps, :list, required: true)
  attr(:unseeded_tps, :list, required: true)
  attr(:seed_index, :integer, required: true)

  def single_participant_modal(assigns) do
    ~H"""
    <div>
      <.modal
        :if={@show}
        id="participants-modal"
        show={@show}
        hide_callback={@hide_callback}
        hide_callback_target={@target}
        class="px-4 py-6 gap-y-6"
      >
        <h3 class="mb-6">
          Select a participant for seed <%= @seed_index %>
        </h3>
        <div id="participants-modal-controls" class="mb-6 md:flex md:items-center gap-x-6">
          <.form
            :let={f}
            for={to_form(%{}, as: :participants_modal_search)}
            phx-change="search-unseeded-participants"
            phx-target={@target}
            class="flex items-center gap-x-4"
          >
            <div class="relative flex items-center">
              <.form_text_input
                id="search-unseeded-participants-input"
                form={f}
                field={:search_term}
                value={@search_term}
                phx-debounce={100}
                class="w-64 px-0 border-2 rounded-md bg-blackish"
                placeholder="Search"
              />
              <.svg icon={:search} width="24" height="24" class="absolute right-0 fill-grey-light" />
            </div>
          </.form>
          <div id="participants-modal-checkboxes" class="">
            <.form
              :let={f}
              for={to_form(%{}, as: :participants_modal_filters)}
              phx-change="customize-participants-modal-filters"
              phx-target={@target}
              class="flex items-center gap-x-4"
            >
              <.checkbox
                form={f}
                field_name={:unseeded_only}
                checked={@unseeded_only}
                label="Show only unseeded"
                label_class="mb-0 ml-6"
                id="customize-participants-modal-filters-checkbox-unseeded"
              />
              <.checkbox
                form={f}
                field_name={:unlocked_only}
                checked={@unlocked_only}
                label="Show only unlocked"
                label_class="mb-0 ml-6"
                id="customize-participants-modal-filters-checkbox-unlocked"
              />
            </.form>
          </div>
        </div>
        <.form
          :let={f}
          for={to_form(%{}, as: :select_single_participants)}
          phx-submit="select-single-participant-for-seed-index"
          phx-value-seed-index={@seed_index}
          phx-target={@target}
          class="items-center"
        >
          <%= hidden_input(f, :seed_index, value: @seed_index) %>
          <div id="unseeded-participants-selector" class="mb-6 overflow-y-scroll max-h-80">
            <.table
              id="participants-modal-list"
              rows={
                build_rows(@unseeded_only, @unlocked_only, @unseeded_tps, @seeded_tps, @search_term)
              }
              row_id={&"participants-modal-list-row-#{&1.id}"}
              class="border-collapse"
            >
              <:col :let={tp} label="Name">
                <div :if={!tp.is_seed_index_locked} class="flex items-center">
                  <%= label(class: "mb-0") do %>
                    <%= radio_button(f, :selected, tp.id, class: "mr-4") %>
                    <%= tp.name %>
                  <% end %>
                </div>
                <div :if={tp.is_seed_index_locked} class="text-grey-light">
                  <%= tp.name %>
                </div>
              </:col>
              <:col :let={tp} label="Email"><%= tp.email %></:col>
              <:col :let={tp} label="Creation Date">
                <.localised_datetime
                  datetime={tp.inserted_at}
                  timezone={@timezone}
                  locale={@locale}
                  type={:date}
                />
              </:col>
              <:col :let={tp} label="Seed">
                <div class="text-xl text-primary">
                  <%= tp.seed_index %>
                </div>
              </:col>
            </.table>
          </div>

          <div class="flex justify-between">
            <.button
              type="button"
              button_type={:primary_ghost}
              id="participants-modal-cancel-button"
              phx-click="hide-single-participant-modal"
              phx-target={@target}
              class="text-primary"
            >
              &lt; Cancel
            </.button>
            <.button type="submit" button_type={:primary} id="participants-modal-confirm-button">
              Add to seed <%= @seed_index %>
            </.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:disabled, :boolean, default: false)
  attr(:form, :any, required: true)
  attr(:field_name, :any, required: true)
  attr(:checked, :boolean, required: true)
  attr(:label, :string, required: true)
  attr(:label_class, :string, default: "control-label ml-4")
  attr(:hidden_values, :any, default: %{})

  defp checkbox(assigns) do
    ~H"""
    <div id={@id} class="flex items-center">
      <%= checkbox(@form, @field_name,
        checked: @checked,
        disabled: @disabled,
        class: "h-4 w-4 text-primary focus:ring-indigo-500 border-gray-300 rounded",
        id: "#{@id}-checkbox"
      ) %>
      <%= label(@form, @field_name, @label, class: @label_class) %>
      <%= for {field, value} <- @hidden_values do %>
        <%= hidden_input(@form, field, value: value, id: "#{@id}-participant-id") %>
      <% end %>
    </div>
    """
  end

  defp build_rows(unseeded_only, unlocked_only, unseeded_tps, seeded_tps, search_term) do
    tps = if unseeded_only, do: unseeded_tps, else: seeded_tps ++ unseeded_tps
    tps = if unlocked_only, do: Enum.filter(tps, &(!&1.is_seed_index_locked)), else: tps

    split_search_terms =
      (search_term || "")
      |> String.downcase()
      |> String.trim()
      |> String.split()

    if Enum.any?(split_search_terms) do
      Enum.filter(tps, fn
        %{name: tp_name} when is_binary(tp_name) ->
          downcased_name = String.downcase(tp_name)
          Enum.all?(split_search_terms, &String.contains?(downcased_name, &1))

        _ ->
          false
      end)
    else
      tps
    end
  end
end
