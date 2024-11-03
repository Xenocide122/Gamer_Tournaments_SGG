defmodule StridentWeb.TeamLive.Components do
  @moduledoc false
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def members(assigns) do
    ~H"""
    <div class="py-4 sm:py-5 xl:grid xl:grid-cols-3 sm:gap-1">
      <dt class="mb-4 ">
        <p class="mb-2 text-grey-light">
          <%= @title %>
        </p>
        <%= add_description(assigns) %>
      </dt>
      <div>
        <div id={"view-#{@id}"} class="flex justify-between block w-full mt-1 align-middle sm:mt-0">
          <div>
            <%= for member <- @members do %>
              <div class="flex mb-2">
                <img class="w-8 h-8 mr-3 rounded-full" src={member.user.avatar_url} alt="" />
                <span class="pt-1">
                  <%= member.user.display_name %>
                </span>
              </div>
            <% end %>
          </div>
        </div>
        <div id={"edit-#{@id}"} class="hidden w-full lg:col-span-2">
          <div class="flex mt-1 align-middle lg:justify-between sm:mt-0">
            <div class="w-full">
              <%= for member <- @members do %>
                <div class="flex justify-between mb-2">
                  <div class="flex">
                    <img class="w-8 h-8 mr-3 rounded-full" src={member.user.avatar_url} alt="" />
                    <div class="pt-1 truncate">
                      <%= member.user.display_name %>
                    </div>
                  </div>
                  <%= if Enum.count(@members) > 1 do %>
                    <button
                      phx-click="remove"
                      phx-value-id={member.id}
                      phx-value-user-id={member.user_id}
                      phx-value-type={@type}
                      class=""
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="w-6 h-6 text-red-900"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        stroke-width="2"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M15 12H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                    </button>
                  <% end %>
                </div>
              <% end %>
              <div id={"add-#{@id}"} class="block mt-4 ml-2 ">
                <button
                  phx-click={click_add_another(@id)}
                  type="button"
                  class="flex space-x-2 text-sm align-center text-primary hover:text-primary-dark focus:outline-none focus:ring-none"
                >
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                    <path d={StridentWeb.Common.SvgUtils.path(:add_fill)} />
                  </svg>
                  <span class="mt-1 ml-2 text-xs truncate">
                    Add another
                  </span>
                </button>
              </div>
              <div id={"data-#{@id}"} class="hidden">
                <.select id={@id} options={@team} type={@type} members={@members} />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex items-start justify-end lg:ml-4">
        <div id={"update-#{@id}"} class="block">
          <button
            phx-click={click_update(@id)}
            type="button"
            class="text-primary hover:text-primary-dark focus:outline-none focus:ring-none"
          >
            Update
          </button>
        </div>
        <div id={"save-#{@id}"} class="hidden lg:ml-4 lg:flex-shrink-0">
          <button
            phx-click={click_cancel(@id, @type)}
            type="button"
            class="mr-4 text-gray-300 hover:text-gray-500 focus:outline-none focus:ring-none"
          >
            Cancel
          </button>
          <button
            phx-click={click_save(@id, @type)}
            type="button"
            class="text-primary hover:text-primary-dark focus:outline-none focus:ring-none"
          >
            Save
          </button>
        </div>
      </div>
    </div>
    """
  end

  def select(assigns) do
    ~H"""
    <div class="">
      <div phx-click-away={JS.hide(to: "#list-#{@id}")} class="">
        <button
          phx-click={click_select(@id)}
          type="button"
          class="relative w-full py-2 pl-3 pr-10 text-left border rounded-md cursor-default bg-blackish border-primary focus:outline-none focus:ring-1 focus:ring-primary-dark focus:border-primary-dark sm:text-sm"
          aria-haspopup="listbox"
          aria-expanded="true"
          aria-labelledby="listbox-label"
        >
          <div class="block h-6">
            Select
          </div>
          <span class="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none">
            <!-- Heroicon name: solid/selector -->
            <svg
              class="w-5 h-5 text-gray-400"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                clip-rule="evenodd"
              />
            </svg>
          </span>
        </button>
        <ul
          id={"list-#{@id}"}
          class="absolute z-10 hidden w-auto py-1 mt-1 overflow-auto text-base rounded-md bg-blackish max-h-60 ring-1 ring-primary ring-opacity-5 focus:outline-none sm:text-sm"
          tabindex="-1"
          role="listbox"
          aria-labelledby="listbox-label"
          aria-activedescendant="listbox-option-3"
        >
          <%= for option <- @options do %>
            <%= if option in @members or option.type == :captain do %>
              <li
                disabled
                class="relative py-2 pl-3 text-white cursor-default pr-9"
                id="listbox-option-0"
                role="option"
              >
                <span class="block mr-4 font-normal truncate">
                  <%= option.user.display_name %>
                </span>
                <span class="absolute inset-y-0 right-0 flex items-center pr-4 text-indigo-600">
                  <%= if option.type == :captain do %>
                    <span>C</span>
                  <% else %>
                    <!-- Heroicon name: solid/check -->
                    <svg
                      class="w-5 h-5"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% end %>
                </span>
              </li>
            <% else %>
              <li
                phx-click={select_option(@id, option.id, @type)}
                class="relative py-2 pl-3 text-white cursor-default hover:bg-primary hover:text-gray-900 hover:font-semibold pr-9"
                id="listbox-option-0"
                role="option"
              >
                <span class="block font-normal truncate">
                  <%= option.user.display_name %>
                </span>
              </li>
            <% end %>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def socials(assigns) do
    ~H"""
    <div class="py-4 sm:py-5 xl:grid xl:grid-cols-3 sm:gap-1">
      <dt class="mb-4 text-grey-light">
        <%= @title %>
      </dt>
      <div>
        <div id={"view-#{@id}"} class="flex justify-between block w-full mt-1 align-middle sm:mt-0">
          <div>
            <%= for social <- @team.social_media_links do %>
              <div class="flex mb-2 space-x-2 align-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d={StridentWeb.Common.SvgUtils.path(social.brand)}></path>
                </svg>
                <span class="truncate">
                  <%= social.handle %>
                </span>
              </div>
            <% end %>
          </div>
        </div>
        <div id={"edit-#{@id}"} class="hidden w-full lg:col-span-2">
          <div class="flex justify-between mt-1 sm:mt-0">
            <div class="w-full">
              <%= for social <- @team_socials do %>
                <div class="flex justify-between mb-2">
                  <div class="flex justify-between space-x-2">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                    >
                      <path d={StridentWeb.Common.SvgUtils.path(social.brand)}></path>
                    </svg>
                    <span class="truncate">
                      <%= social.handle %>
                    </span>
                  </div>
                  <button phx-click="remove" phx-value-id={social.id} phx-value-type={@type} class="">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="w-6 h-6 text-red-900"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      stroke-width="2"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15 12H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                  </button>
                </div>
              <% end %>
              <div id={"add-#{@id}"} class="mt-4 ml-2">
                <button
                  phx-click={click_add_another(@id)}
                  type="button"
                  class="flex space-x-2 text-sm align-center text-primary hover:text-primary-dark focus:outline-none focus:ring-none"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="w-6 h-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M12 9v3m0 0v3m0-3h3m-3 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span class="mt-1 ml-2 text-xs truncate">
                    Add another
                  </span>
                </button>
              </div>
              <div id={"data-#{@id}"} class="hidden">
                <form phx-submit={
                  JS.toggle(to: "#data-#{@id}")
                  |> JS.toggle(to: "#add-#{@id}")
                  |> JS.push("add_social")
                }>
                  <div class="flex justify-between">
                    <input
                      name="url"
                      type="text"
                      autocomplete="off"
                      class="w-10/12 bg-grey-medium border border-grey-light rounded py-2.5 px-5 focus:border-primary focus:bg-grey-medium focus:ring-1 focus:ring-primary"
                      placeholder="Link to profile"
                    />
                    <button type="submit">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="w-6 h-6 text-primary"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        stroke-width="2"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M12 9v3m0 0v3m0-3h3m-3 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex items-start justify-end lg:ml-4">
        <div id={"update-#{@id}"} class="block">
          <button
            phx-click={click_update(@id)}
            type="button"
            class="text-primary hover:text-primary-dark focus:outline-none focus:ring-none"
          >
            Update
          </button>
        </div>
        <div id={"save-#{@id}"} class="hidden lg:ml-4 lg:flex-shrink-0">
          <button
            phx-click={click_cancel(@id, @type)}
            type="button"
            class="mr-4 text-gray-300 hover:text-gray-500 focus:outline-none focus:ring-none"
          >
            Cancel
          </button>
          <button
            phx-click={click_save(@id, @type)}
            type="button"
            class="text-primary hover:text-primary-dark focus:outline-none focus:ring-none"
          >
            Save
          </button>
        </div>
      </div>
    </div>
    """
  end

  def modal(assigns) do
    ~H"""
    <form
      phx-submit="confirm_removal"
      js-trigger-confirmation-required
      js-action-confirmation-required={JS.toggle(to: "#confirmation")}
    >
      <input type="hidden" name="id" value={"#{@id}"} />
      <div
        id="confirmation"
        class="fixed inset-0 z-10 hidden overflow-y-auto"
        aria-labelledby="modal-title"
        role="dialog"
        aria-modal="true"
      >
        <div class="flex items-end justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
          <div class="fixed inset-0 transition-opacity bg-blackish bg-opacity-75" aria-hidden="true">
          </div>
          <!-- This element is to trick the browser into centering the modal contents. -->
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          <div class="relative inline-block px-4 pt-5 pb-4 overflow-hidden text-left align-bottom transition-all transform bg-gray-800 rounded-md shadow-xl sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
            <div class="sm:flex sm:items-start">
              <div class="flex items-center justify-center flex-shrink-0 w-12 h-12 mx-auto bg-red-800 bg-opacity-25 rounded-full sm:mx-0 sm:h-10 sm:w-10">
                <!-- Heroicon name: outline/exclamation -->
                <svg
                  class="w-5 h-5 text-red-600"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <div class="font-normal text-white" id="modal-title">
                  Remove yourself as Team Manager?
                </div>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    Are you sure you want to be removed as Team Manager? You will immediately lose all Team Manager permissions.
                  </p>
                </div>
                <div class="relative flex items-start my-4">
                  <div class="flex items-center h-5">
                    <input
                      id="remove-me"
                      name="remove-me"
                      type="checkbox"
                      class="w-5 h-5 border-gray-300 rounded focus:ring-primary focus:ring-offset-0 text-primary checked:bg-gray-800 checked:border-primary"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <p class={"font-normal #{@text}"} id="modal-title">
                      Remove yourself as Team Manager?
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse gap-x-4">
              <button class="mb-2 text-gray-400 bg-red-800 border-red-800 btn btn--secondary">
                Change
              </button>
              <div
                phx-click={JS.hide(to: "#confirmation")}
                class="mb-2 capitalize btn btn--primary-ghost"
              >
                Cancel
              </div>
            </div>
          </div>
        </div>
      </div>
    </form>
    """
  end

  defp click_add_another(js \\ %JS{}, id) do
    js
    |> JS.toggle(to: "#add-#{id}")
    |> JS.toggle(
      to: "#data-#{id}",
      in: {"transform transition ease-in-out duration-800", "opacity-0", "opacity-100"},
      out: {"transform transition ease-in-out duration-500", "opacity-100", "opacity-0"}
    )
  end

  defp click_update(js \\ %JS{}, id) do
    js
    |> JS.push("lv:clear-flash")
    |> JS.toggle(to: "#view-#{id}")
    |> JS.toggle(
      to: "#edit-#{id}",
      in: {"transform transition ease-in-out duration-500", "opacity-0", "opacity-100"},
      out: {"transform transition ease-in-out duration-500", "opacity-100", "opacity-0"}
    )
    |> JS.toggle(to: "#update-#{id}")
    |> JS.show(to: "#add-#{id}")
    |> JS.toggle(
      to: "#save-#{id}",
      in: {"transform transition ease-in-out duration-500", "opacity-0", "opacity-100"},
      out: {"transform transition ease-in-out duration-500", "opacity-100", "opacity-0"}
    )
  end

  defp click_cancel(js \\ %JS{}, id, type) do
    js
    |> JS.toggle(to: "#view-#{id}")
    |> JS.hide(to: "#data-#{id}")
    |> JS.toggle(to: "#edit-#{id}")
    |> JS.toggle(to: "#update-#{id}")
    |> JS.toggle(to: "#save-#{id}")
    |> JS.push("update_cancel", value: %{type: type})
  end

  defp click_save(js \\ %JS{}, id, type) do
    js
    |> JS.toggle(to: "#view-#{id}")
    |> JS.toggle(to: "#edit-#{id}")
    |> JS.toggle(to: "#update-#{id}")
    |> JS.toggle(to: "#save-#{id}")
    |> JS.push("save", value: %{type: type})
  end

  defp select_option(js \\ %JS{}, id, option_id, type) do
    js
    |> JS.toggle(
      to: "#data-#{id}",
      in: {"transform transition ease-in-out duration-800", "opacity-0", "opacity-100"},
      out: {"transform transition ease-in-out duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.toggle(
      to: "#add-#{id}",
      in: {"transform transition ease-in-out duration-800", "opacity-0", "opacity-100"},
      out: {"transform transition ease-in-out duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.push("add", value: %{id: option_id, type: type})
  end

  defp click_select(js \\ %JS{}, id) do
    js
    |> JS.toggle(
      to: "#list-#{id}",
      in: {"transform transition ease-in-out duration-500", "opacity-0", "opacity-100"},
      out: {"transform transition ease-in-out duration-500", "opacity-100", "opacity-0"}
    )
  end

  def add_description(%{description: _description} = assigns) do
    ~H"""
    <p class="w-48 text-xs">
      <%= @description %>
    </p>
    """
  end

  def add_description(assigns) do
    ~H"""

    """
  end
end
