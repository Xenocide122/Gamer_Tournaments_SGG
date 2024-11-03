defmodule StridentWeb.Schema.Mutations.Apple do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias StridentWeb.Resolvers.AppleResolver

  input_object :apple_full_name do
    field :name_prefix, :string
    field :given_name, :string
    field :name_suffix, :string
    field :nickname, :string
    field :family_name, :string
    field :middle_name, :string
  end

  input_object :apple_login_input do
    field :identity_token, non_null(:string)
    field :authorization_code, non_null(:string)
    field :authorized_scopes, non_null(list_of(non_null(:string)))
    field :real_user_status, non_null(:integer)
    field :nonce, non_null(:string)
    field :user, non_null(:string)
    field :full_name, non_null(:apple_full_name)
    field :email, :string
    field :state, :string

    field :locale, non_null(:string)
    field :timezone, non_null(:string)
  end

  object :apple_mutations do
    @desc "Login with apple to your user account"
    field :apple_login, :login_result do
      arg(:input, non_null(:apple_login_input))
      resolve(&AppleResolver.apple_login/3)
    end
  end
end
