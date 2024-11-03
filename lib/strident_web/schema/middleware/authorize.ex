defmodule StridentWeb.Schema.Middleware.Authorize do
  @moduledoc """
  Houses authorization logic.
  """

  @behaviour Absinthe.Middleware
  require Logger

  def call(resolution, rules) do
    for rule <- rules, reduce: resolution do
      resolution -> restriction(rule, resolution)
    end
  end

  def restriction(:auth, %{errors: []} = resolution) do
    if is_nil(get_current_user(resolution)) do
      Absinthe.Resolution.put_result(resolution, status_code_401(resolution))
    else
      resolution
    end
  end

  defp status_code_401(resolution), do: error_for_resolution(resolution, 401, "Unauthenticated.")

  defp error_for_resolution(%{parent_type: %{identifier: :query}}, status_code, message) do
    {:error, [{:message, message}, {"statusCode", status_code}]}
  end

  defp error_for_resolution(%{parent_type: %{identifier: :mutation}}, status_code, message) do
    {:error, [{:message, message}, {:status_code, status_code}]}
  end

  defp error_for_resolution(_resolution, _status_code, _message) do
    {:error, [{:message, "Unknown error occurred in graphql resolution."}, {:status_code, 500}]}
  end

  defp get_current_user(resolution) do
    case resolution.context do
      %{current_user: current_user} when not is_nil(current_user) ->
        Logger.metadata(user_id: current_user.id)
        current_user

      _ ->
        nil
    end
  end
end
