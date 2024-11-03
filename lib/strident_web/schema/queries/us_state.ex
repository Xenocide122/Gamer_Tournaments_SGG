defmodule StridentWeb.Schema.Queries.UsState do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias Strident.UsStates

  object :us_state_queries do
    @desc "Get US states short/long name mappings"
    field :us_state_mappings, non_null(list_of(non_null(:us_state_mapping))) do
      resolve(fn _, _, _ ->
        UsStates.us_states()
        |> Enum.map(fn {human_name, code} ->
          %{human_name: human_name, code: code}
        end)
        |> then(&{:ok, &1})
      end)
    end
  end
end
