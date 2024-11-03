defmodule StridentWeb.Components.SocialMediaShareComponent do
  @moduledoc false
  use StridentWeb, :live_component
  alias StridentWeb.SegmentAnalyticsHelpers
  alias Phoenix.LiveView.JS

  @social_media_items [:facebook, :twitter, :linkedin, :reddit]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal_small id={@id}>
        <:header>
          <h3 class="px-4 pt-2">Share</h3>
        </:header>
        <div class="flex justify-center pt-2">
          <hr class="border-t-0.5 border-grey-light" width="95%" />
        </div>

        <div class="flex justify-between px-8 pt-4">
          <%= for social_media_item <- @social_media_items do %>
            <div class="flex flex-col items-center justify-center">
              <button
                class="flex p-1 uppercase rounded-md inner-glow btn btn--primary-ghost"
                type="button"
                phx-value-social-media={social_media_item}
                phx-click={JS.push("send-analytics", target: @myself)}
              >
                <a
                  href={generate_social_media_link(social_media_item, @page_link)}
                  target="_blank"
                  rel="nofollow"
                >
                  <.svg icon={social_media_item} />
                </a>
              </button>
              <p class="pt-2 text-sm capitalize text-primary"><%= to_string(social_media_item) %></p>
            </div>
          <% end %>
        </div>

        <div class="flex justify-center py-4">
          <hr class="border-t-0.5 border-grey-light" width="95%" />
        </div>

        <form class="flex flex-col justify-center px-8">
          <input
            id="copyable-link"
            class="shadow-md form-input max-h-9"
            name="tournament_link"
            type="text"
            value={@page_link}
            autocomplete="off"
            placeholder="Registration Link"
          />

          <span id="link-copied" class="hidden text-center">
            Link copied!
          </span>

          <div id="copy-button" class="flex justify-center mt-4">
            <button
              class="py-1 text-white uppercase btn btn--primary-ghost inner-glow"
              type="button"
              phx-value-social-media="direct-link"
              phx-click={
                JS.dispatch("grilla:clipcopyinput",
                  to: "#copyable-link"
                )
                |> JS.remove_class("hidden", to: "#link-copied")
                |> JS.remove_class("mt-6", to: "#copy-button")
                |> JS.add_class("border-primary text-primary shadow-primary",
                  to: "#copyable-link"
                )
                |> JS.push("send-analytics", target: @myself)
              }
            >
              Copy Link
            </button>
          </div>
        </form>
      </.modal_small>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{id: id, page_link: page_link} = assigns

    socket
    |> assign(:id, id)
    |> assign(:page_link, page_link)
    |> assign(:social_media_items, @social_media_items)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("send-analytics", %{"social-media" => value}, socket) do
    %{assigns: %{page_link: page_link}} = socket

    socket
    |> SegmentAnalyticsHelpers.track_segment_event("Share Modal Opened", %{
      url: page_link,
      social_media: value
    })
    |> then(&{:noreply, &1})
  end

  defp generate_social_media_link(:reddit, page_link),
    do: "http://www.reddit.com/submit?url=#{page_link}"

  defp generate_social_media_link(:facebook, page_link),
    do: "http://www.facebook.com/sharer.php?u=#{page_link}"

  defp generate_social_media_link(:twitter, page_link),
    do: "https://twitter.com/intent/tweet?text=#{page_link}"

  defp generate_social_media_link(:linkedin, page_link),
    do: "https://www.linkedin.com/shareArticle?mini=true&title=Stride&url=#{page_link}"
end
