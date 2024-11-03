defmodule StridentWeb.Schema.Queries.Twitch do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias StridentWeb.Resolvers.TwitchResolver

  object :twitch_queries do
    @desc "URL for logging in from native app. Just link to it on device browser."
    field :twitch_oauth_url, non_null(:string) do
      arg(:code_verifier, non_null(:string))
      resolve(&TwitchResolver.twitch_oauth_url/3)
    end
  end
end
