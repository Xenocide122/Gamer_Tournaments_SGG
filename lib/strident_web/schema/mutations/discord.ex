defmodule StridentWeb.Schema.Mutations.Discord do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias StridentWeb.Resolvers.DiscordResolver

  input_object :discord_login_input do
    @desc """
    The `code_verifier` returned from Discord
    """
    field :code_verifier, non_null(:string)

    @desc """
    The `authorizationCode` returned from Discord
    """
    field :authorization_code, non_null(:string)

    field :locale, non_null(:string)
    field :timezone, non_null(:string)
  end

  object :discord_mutations do
    @desc "Login with discord to your user account"
    field :discord_login, :login_result do
      arg(:input, non_null(:discord_login_input))
      resolve(&DiscordResolver.discord_login/3)
    end
  end
end
