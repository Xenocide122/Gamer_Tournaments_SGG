defmodule StridentWeb.PlayNowLive do
  @moduledoc false
  use StridentWeb, :live_view

  alias StridentWeb.PlayNowLive.InterestedPlayerForm

  def render(assigns) do
    ~H"""
    <div class="py-16">
      <div class="play-now">
        <div class="container">
          <div class="mb-16 text-center uppercase">
            <h2>Take part in our</h2>
            <h1 class="text-primary">
              hand-picked tournaments
            </h1>
          </div>

          <div class="play-now__form">
            <.live_component
              id="interested-player-form"
              module={InterestedPlayerForm}
              current_user={@current_user}
              interest_registered={@interest_registered}
              timezone={@timezone}
              locale={@locale}
            />
          </div>
        </div>

        <div class="play-now__line" />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Play Now")
    |> assign(:interest_registered, get_connect_params(socket)["interest_registered"])
    |> then(&{:ok, &1})
  end
end
