defmodule StridentWeb.LayoutView do
  use StridentWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  @doc """
  The application environment, one of the usual Mix envs (dev/test/prod)
  """
  @spec mix_env() :: String.t()
  def mix_env do
    Application.get_env(:strident, :env) |> to_string()
  end

  @doc """
  The ID used for google analytics. Different between prod and staging.
  """
  @spec google_analytics_id() :: String.t() | nil
  def google_analytics_id do
    case System.get_env("GOOGLE_ANALYTICS_ID") do
      nil -> nil
      id when is_binary(id) -> if String.length(id) > 0, do: id
    end
  end

  @doc """
  The write key used for Segment javascript integration. Different between prod and staging.
  """
  @spec segment_javascript_write_key() :: String.t() | nil
  def segment_javascript_write_key do
    System.get_env("SEGMENT_JAVASCRIPT_WRITE_KEY")
  end
end
