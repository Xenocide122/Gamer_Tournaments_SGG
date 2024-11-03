defmodule StridentWeb.DeadViews.Container do
  @moduledoc false
  use Phoenix.Component
  alias Strident.ImgproxyUrl

  attr(:id, :string, required: true)
  attr(:class, :string, default: "")
  slot(:side_menu, doc: "Containers side menu")
  slot(:inner_block, required: true)

  def container(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <%= render_slot(@side_menu) %>

      <div class={["pt-28 w-full", @class]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:image_url, :string, default: "")
  slot(:side_menu, doc: "Containers side menu")
  slot(:inner_block, required: true)

  attr(:show_stream, :boolean, default: false)
  attr(:twitch_channel_name, :any, default: nil)
  attr(:youtube_channel_src, :any, default: nil)
  attr(:width, :integer, required: true)
  attr(:height, :integer, required: true)
  attr(:gravity, :atom, default: :sm)
  attr(:enlarge, :boolean, default: false)
  attr(:extension, :any, default: nil)
  attr(:resize, :atom, default: :auto)

  def container_bg_image(assigns) do
    %{image_url: image_url} = assigns

    assigns =
      if Application.get_env(:strident, :use_image_proxy, true) do
        opts =
          assigns
          |> Map.take([:width, :height, :resize, :enlarge, :gravity, :extension])
          |> Map.to_list()

        src = ImgproxyUrl.build_img_src(image_url, opts)
        assign(assigns, :src, src)
      else
        assign(assigns, :src, image_url)
      end

    ~H"""
    <div id={@id} class="relative w-full h-full">
      <div
        :if={not @show_stream or (@show_stream and !@twitch_channel_name and !@youtube_channel_src)}
        class="absolute w-full min-h-screen xl:min-h-[650px] bg-[length:auto_425px] bg-top bg-no-repeat md:bg-cover -z-10 md:mt-8 lg:mt-14"
        style={"background-image: linear-gradient(0deg, #000D1F 0%, rgba(0, 13, 31, 0.75) 66.34%, rgba(0, 13, 31, 0.00) 100%), url(#{@src})"}
      >
      </div>

      <div
        :if={@show_stream and !!@twitch_channel_name}
        id="twitch-embed"
        phx-hook="TwitchEmbed"
        data-channel-name={@twitch_channel_name}
        data-show-layout="video"
        data-show-client-full-screen="true"
        class="absolute w-full min-h-screen -z-10"
      >
      </div>

      <%!-- TODO: Probably best if we make this into hook, to setup size of the screen --%>
      <%!-- <iframe
        :if={@show_stream and !!@youtube_channel_src}
        width="854"
        height="480"
        src={@youtube_channel_src}
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen
        class="absolute -z-10"
      >
      </iframe> --%>

      <%= render_slot(@side_menu) %>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:inner_class, :string, default: "")
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def colored_card(assigns) do
    ~H"""
    <div id={@id} class={[@class, "rounded-xl bg-gradient-to-l from-[#ff6802] to-[#03d5fb] p-px"]}>
      <div class={["bg-blackish rounded-xl", @inner_class]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
