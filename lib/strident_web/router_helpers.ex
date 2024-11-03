# credo:disable-for-this-file Strident.CredoChecks.OnlySafeStaticUrl
defmodule StridentWeb.RouterHelpers do
  @moduledoc """
  Useful functions for custom routing logic
  """
  alias Strident.Accounts.User
  alias Strident.UrlGeneration
  alias StridentWeb.Endpoint
  alias StridentWeb.Router.Helpers, as: Routes

  @doc """
  Returns the path to the profile of either
  a Pro or User.

  The Pro profile is "preferred" but
  if User has `is_pro=false` or no assocated Pro
  then the User profile is returned.
  """
  @spec profile_path(User.t() | nil) :: String.t()
  def profile_path(%{slug: slug}) when is_binary(slug) do
    Routes.user_show_path(Endpoint, :show, slug)
  end

  def profile_path(_) do
    Routes.live_path(Endpoint, StridentWeb.HomeLive)
  end

  @doc """
  Like the default `static_url/2` function but guaranteed https in prod

  Because our Endpoint config has `url` with port 80, we need this.
  """
  if Application.compile_env(:strident, :env) == :prod do
    def safe_static_url(path) do
      StridentWeb.Endpoint
      |> Routes.static_url(path)
      |> UrlGeneration.absolute_path()
    end
  else
    def safe_static_url(path) do
      StridentWeb.Endpoint
      |> Routes.static_url(path)
      |> UrlGeneration.absolute_path()
    end
  end
end
