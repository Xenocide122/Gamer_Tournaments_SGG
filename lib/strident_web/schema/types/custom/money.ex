defmodule StridentWeb.Schema.Types.Custom.Money do
  use Absinthe.Schema.Notation

  @moduledoc """
  The Money scalar type allows arbitrary currency values to be passed in and out.
  Requires `{:ex_money, "~> 5.8"}` package: https://github.com/kipcole9/money
  """

  object :money do
    field :amount, :decimal
    field :currency, :string
  end

  input_object :money_input do
    field :amount, non_null(:decimal)
    field :currency, non_null(:string)
  end

  object :money_result do
    field :errors, list_of(non_null(:input_error))
    field :money, :money
  end
end
