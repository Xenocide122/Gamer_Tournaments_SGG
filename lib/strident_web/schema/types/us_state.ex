defmodule StridentWeb.Schema.Types.UsState do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Strident.UsStates

  enum :us_state_code do
    UsStates.us_states()
    |> Map.values()
    |> values()
  end

  object :us_state_mapping do
    field :human_name, non_null(:string)
    field :code, non_null(:us_state_code)
  end
end
