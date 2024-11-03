defmodule StridentWeb.ConfirmEmailLive do
  @moduledoc false
  use StridentWeb, :live_view
  require Logger
  alias StridentWeb.UserSettingsLive.ConfirmEmailComponent

  on_mount({StridentWeb.InitAssigns, :default})

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container pb-20 mt-32">
      <.card class="mb-5">
        <h4 class="mb-2">
          Confirm your email
        </h4>
        <.live_component
          timezone={@timezone}
          locale={@locale}
          id="confirm-email-component"
          module={ConfirmEmailComponent}
          current_user={@current_user}
        />
      </.card>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
