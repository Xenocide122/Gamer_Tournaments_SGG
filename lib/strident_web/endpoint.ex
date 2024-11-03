defmodule StridentWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :strident

  plug(StridentWeb.Plugs.HealthCheck)

  # hack to get correct domain
  # would be better to read this from config but we need it at compile time
  @domain (case({Application.compile_env(:strident, :env), !!System.get_env("IS_STAGING")}) do
             {:prod, false} -> "stride.gg"
             {:prod, true} -> "strident-staging.fly.dev"
             _ -> nil
           end)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
                     http_only: true,
                     key: "_strident_key",
                     same_site: "None",
                     secure: true,
                     signing_salt: "6qSENCxr",
                     store: :cookie,
                     sign: true
                   ]
                   |> then(&if @domain, do: Keyword.put(&1, :domain, @domain), else: &1)

  if sql_sandbox = Application.compile_env(:strident, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox, sandbox: sql_sandbox)
  end

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [:user_agent, session: @session_options]]
  )

  plug(CORSPlug)

  plug(RemoteIp, headers: ["fly-client-ip"])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :strident,
    gzip: false,
    only: StridentWeb.static_paths()
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :strident)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    body_reader: {StridentWeb.Middleware.CacheBodyReader, :read_body, []},
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(StridentWeb.Router)
end
