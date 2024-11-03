defmodule StridentWeb.Middleware.CacheBodyReader do
  @moduledoc """
  This ensures we have access to the raw value of the body on the
  Stride API. It was first added to check the persona-signature included
  in the header of Persona webhooks
  \
  This is taken from the docs:
    https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader
  """
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end
end
