defmodule StridentWeb.Schema.Middleware.MoveErrorsToValue do
  @moduledoc """
  Moves errors from the :errors property to the :value property.
  """
  @behaviour Absinthe.Middleware

  alias Ecto.Changeset
  alias Strident.ChangesetUtils
  alias StridentWeb.Schema.Types.Error

  @doc """
  Moves errors from the :errors property to the :value property.

  This prevents them "bubbling up", in ways we might have to control.
  It particularly is a safeguard against the user seeing them.
  """
  def call(%{errors: [_ | _] = errors} = res, _) when is_list(errors) do
    errors
    |> Enum.with_index()
    |> Enum.map(&to_input_error/1)
    |> List.flatten()
    |> then(&%{res | value: %{errors: &1}, errors: []})
  end

  def call(res, _) do
    res
  end

  @spec to_input_error({Changeset.t() | binary() | map() | Keyword.t(), non_neg_integer()}) ::
          Error.input_error()
  defp to_input_error({%Ecto.Changeset{} = changeset, _with_index}) do
    changeset
    |> ChangesetUtils.error_codes()
    |> Enum.map(fn
      {key, value} ->
        camel_key = key |> to_string() |> Recase.to_camel()
        %{key: camel_key, message: value}
    end)
  end

  defp to_input_error({message, index}) when is_binary(message) do
    %{key: new_key(index), message: message}
  end

  defp to_input_error({map, index}) when is_map(map) do
    Map.put_new(map, :key, new_key(index))
  end

  defp to_input_error({kw, index}) when is_list(kw) do
    kw
    |> Keyword.put_new(:key, new_key(index))
    |> Map.new()
  end

  @spec new_key(non_neg_integer()) :: String.t()
  defp new_key(index) do
    "error #{index}"
  end
end
