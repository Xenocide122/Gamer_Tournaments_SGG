defmodule StridentWeb.Plugs.LogGraphqlDocument do
  @moduledoc """
  Copied from Absinthe.Plug

  Simply logs the graphql document, in a condensed but reaedable format.
  """
  require Logger
  alias Absinthe.Plug.Request
  alias Strident.Accounts.User

  @behaviour Plug

  def init(opts), do: opts

  @absinthe_plug_opts [schema: StridentWeb.Schema, log_level: :info]

  def call(conn, _opts) do
    tap(conn, &log_graphql_doc/1)
  end

  defp log_graphql_doc(conn) do
    user_id =
      case Map.get(conn.assigns, :current_user) do
        %User{id: user_id} -> user_id
        _ -> nil
      end

    user_string =
      if user_id do
        "user #{user_id}"
      else
        "anonymous user"
      end

    config = Absinthe.Plug.init(@absinthe_plug_opts)
    config = Absinthe.Plug.update_config(conn, config)

    case Request.parse(conn, config) do
      {:ok, _conn, %Request{} = request} ->
        for query <- request.queries, is_binary(query.document) do
          doc_string = replace_dupe_spaces(query.document)
          logger_message = "Received from #{user_string} GraphQL document #{inspect(doc_string)}"

          logger_metadata = if user_id, do: %{user_id: user_id}, else: %{}
          Logger.info(logger_message, logger_metadata)
        end

      _ ->
        :noop
    end
  end

  defp replace_dupe_spaces(nil), do: nil

  defp replace_dupe_spaces(string) do
    Regex.replace(~r/[ ]+/, string, " ")
  end
end
