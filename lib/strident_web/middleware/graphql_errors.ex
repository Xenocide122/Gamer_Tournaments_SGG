defmodule StridentWeb.Middleware.GraphqlErrors do
  @moduledoc """
  Detects Ecto.Changeset errors in Absinthe resolution and makes them user friendly
  """
  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution

  def call(%{errors: [%Ecto.Changeset{} = cs]} = resolution, _config) do
    Resolution.put_result(resolution, {
      :error,
      format_changeset(cs)
    })
  end

  def call(%{error: %Ecto.Changeset{} = cs} = resolution, _config) do
    Resolution.put_result(resolution, {
      :error,
      format_changeset(cs)
    })
  end

  def call(resolution, _config) when is_list(resolution.errors) do
    errors =
      Enum.reduce(resolution.errors, [], fn cs, errors ->
        errors ++ format_error(cs)
      end)

    Resolution.put_result(resolution, {
      :error,
      errors
    })
  end

  def call(resolution, _config) do
    resolution
  end

  defp format_error(error) when is_binary(error) or is_atom(error) do
    error
  end

  defp format_error(error) do
    format_changeset(error)
  end

  defp format_changeset(cs) do
    formatter = fn {key, {value, context}} ->
      human_key =
        key
        |> to_string()
        |> String.capitalize()

      [message: "#{human_key} #{translate_error({value, context})}"]
    end

    Enum.map(cs.errors, formatter)
  end

  def translate_error({msg, opts}) do
    Gettext.dgettext(StridentWeb.Gettext, "errors", msg, opts)
  end
end
