defmodule StridentWeb.Schema.Types.Error do
  @moduledoc false

  use Absinthe.Schema.Notation

  @type input_error :: %{
          :message => String.t(),
          :key => String.t() | atom()
        }

  @desc "An error encountered trying to perform the query/mutation"
  object :input_error do
    field :key, :string
    field :message, non_null(:string)
  end
end
