defmodule StridentWeb.Schema.Queries.User do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias StridentWeb.Resolvers.UserResolver
  alias StridentWeb.Schema.Middleware

  object :user_queries do
    @desc "Get a specific user"
    field :user, :user_profile do
      arg(:display_name, non_null(:string))
      resolve(&UserResolver.get_user/3)
    end

    field :me, :user do
      middleware(Middleware.Authorize, [:auth])
      resolve(&UserResolver.get_current_user/3)
    end

    field :registration_validations, :registration_validations do
      resolve(&UserResolver.registration_validations/3)
    end
  end
end
