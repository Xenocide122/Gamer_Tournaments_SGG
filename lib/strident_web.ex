defmodule StridentWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use StridentWeb, :controller
      use StridentWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths,
    do:
      ~w(assets fonts images manifest.json android-chrome-192x192.png android-chrome-256x256.png apple-touch-icon.png favicon-16x16.png favicon-32x32.png favicon.ico mstile-150x150.png robots.txt riot.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: StridentWeb

      import Plug.Conn
      import StridentWeb.Gettext
      alias StridentWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/strident_web/templates",
        namespace: StridentWeb

      use Appsignal.Phoenix.View

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import Phoenix.Component

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {StridentWeb.LayoutView, :live}

      unquote(view_helpers())
      import StridentWeb.LiveViewHelpers
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
      import StridentWeb.LiveViewHelpers
      import StridentWeb.LiveComponentHelpers
    end
  end

  def component do
    quote do
      use Phoenix.Component
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Phoenix.Component
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import StridentWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import StridentWeb.ErrorHelpers
      import StridentWeb.Gettext
      alias StridentWeb.Router.Helpers, as: Routes

      import StridentWeb.RouterHelpers

      import StridentWeb.SegmentAnalyticsHelpers

      import StridentWeb.Components.Containers
      import StridentWeb.Components.Form
      import StridentWeb.Components.LocalisedDate
      import StridentWeb.Components.Flash
      import StridentWeb.Components.Modal
      import StridentWeb.Components.Table
      import StridentWeb.Common.SvgUtils
      import StridentWeb.Components.ProgressBar

      import StridentWeb.DeadViews.Button
      import StridentWeb.DeadViews.Image
      import StridentWeb.DeadViews.TopPersons
      import StridentWeb.DeadViews.Socket
      import StridentWeb.DeadViews.Spinner
      import StridentWeb.DeadViews.Container
      import StridentWeb.CoreComponents

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: StridentWeb.Endpoint,
        router: StridentWeb.Router,
        statics: StridentWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
