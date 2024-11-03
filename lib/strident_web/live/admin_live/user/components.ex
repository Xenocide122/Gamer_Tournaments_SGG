defmodule StridentWeb.AdminLive.User.Components do
  @moduledoc false
  use Phoenix.Component
  import StridentWeb.Common.SvgUtils
  import StridentWeb.Components.Form

  def search_users_filter(assigns) do
    ~H"""
    <div id="admin-user-search" class="flex items-center">
      <.svg icon={:search} width="24" height="24" class="cursor-pointer fill-white" />
      <div class="w-full items-center">
        <.form
          :let={f}
          id="admin-user-search-form"
          for={to_form(%{}, as: :search_users)}
          phx-submit="search"
          phx-change="search"
          phx-debounce="2000"
          class="w-full"
        >
          <.form_text_input
            form={f}
            field={:search_term}
            phx-debounce={2100}
            type="text"
            class="w-full"
            placeholder="Search users by display name or email (min 3 chars)"
            autofocus
          />
        </.form>
      </div>
    </div>
    """
  end
end
