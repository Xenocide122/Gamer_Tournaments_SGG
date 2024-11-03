defmodule StridentWeb.DeadViews.Image do
  @moduledoc """
  Display images, optionally with cropping/resizing
  """
  use Phoenix.Component
  alias Strident.ImgproxyUrl

  attr(:id, :string, required: true)
  attr(:image_url, :string, required: true)
  attr(:alt, :string, required: true)
  attr(:class, :any, default: nil)

  attr(:width, :integer, default: nil)
  attr(:height, :integer, default: nil)
  attr(:gravity, :atom, default: :sm)
  attr(:enlarge, :boolean, default: false)
  attr(:extension, :any, default: nil)
  attr(:resize, :atom, default: :auto)

  def image(assigns) do
    if Application.get_env(:strident, :use_image_proxy, true) do
      %{image_url: image_url} = assigns

      opts =
        assigns
        |> Map.take([:width, :height, :resize, :enlarge, :gravity, :extension])
        |> Map.to_list()

      src = ImgproxyUrl.build_img_src(image_url, opts)
      assigns = assign(assigns, :src, src)

      ~H"""
      <img id={@id} class={[@class]} width={@width} height={@height} src={@src} alt={@alt} />
      """
    else
      %{image_url: image_url} = assigns

      assigns = assign(assigns, :src, image_url)

      ~H"""
      <img id={@id} class={[@class]} width={@width} height={@height} src={@src} alt={@alt} />
      """
    end
  end

  def imgproxy_url(path, opts), do: ImgproxyUrl.build_img_src(path, opts)
end
