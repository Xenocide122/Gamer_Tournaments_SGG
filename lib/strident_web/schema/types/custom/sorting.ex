defmodule StridentWeb.Schema.Types.Custom.Sorting do
  @moduledoc false
  use Absinthe.Schema.Notation

  enum :sort_order do
    value(:asc)
    value(:desc)
  end
end
