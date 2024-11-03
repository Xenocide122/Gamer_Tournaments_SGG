defmodule StridentWeb.Schema.Types.Pagination do
  @moduledoc false

  use Absinthe.Schema.Notation

  input_object :pagination_args do
    field(:limit, :integer)
    field(:page, :integer)
  end
end
