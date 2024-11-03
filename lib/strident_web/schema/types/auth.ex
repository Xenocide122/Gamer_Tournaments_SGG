defmodule StridentWeb.Schema.Types.Auth do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "A password credential for logging in with email/password"
  object :password_credential do
    field :email, :string

    @desc """
    The UTC datetime when email was confirmed. May be null (unconfirmed).
    If this is NULL, then you cannot trust this user.
    """
    field :confirmed_at, :naive_datetime
  end
end
