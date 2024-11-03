defmodule StridentWeb.AppRedirect do
  @moduledoc """
  Centralized module for app redirect logic
  """

  @doc """
  Returns the full path to replace window location for app redirect
  """
  def path(app_redirect_path), do: path_root() |> Path.join(app_redirect_path)
  defp path_root, do: System.get_env("APP_REDIRECT_SCHEME", "grilla") <> "://"
end
