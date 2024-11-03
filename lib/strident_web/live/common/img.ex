defmodule StridentWeb.Live.Common.IMG do
  @moduledoc false
  def build(img_name) do
    "/images/" <> img_name <> ".png"
  end
end
