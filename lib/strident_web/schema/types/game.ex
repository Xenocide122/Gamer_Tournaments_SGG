defmodule StridentWeb.Schema.Types.Game do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "A Game within our system"
  object :game do
    field :id, non_null(:string)
    field :cover_image_url, non_null(:string)
    field :default_game_banner_url, non_null(:string)
    field :description, non_null(:string)
    field :title, non_null(:string)
    field :slug, non_null(:string)
  end
end
