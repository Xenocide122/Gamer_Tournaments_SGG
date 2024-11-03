defmodule StridentWeb.Middleware.GraphqlAuthentication do
  @moduledoc false

  @behaviour Absinthe.Middleware

  def call(resolution, _config) do
    case resolution.context do
      %{current_user: _} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "not_authorized"})
    end
  end
end
