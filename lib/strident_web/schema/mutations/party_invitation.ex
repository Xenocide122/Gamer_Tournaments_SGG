defmodule StridentWeb.Schema.Mutations.PartyInvitation do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias StridentWeb.Resolvers.PartyInvitationResolver
  alias StridentWeb.Schema.Middleware

  object :party_invitation_reponse do
    field(:errors, list_of(non_null(:input_error)))
    field(:party_member, :party_member)
  end

  object :party_invitation_mutations do
    @desc """
    User Accepts Party Invitation
    """
    field :accept_party_invitation, :party_invitation_reponse do
      arg(:tournament_id, non_null(:string))
      arg(:invitation_id, non_null(:string))
      middleware(Middleware.Authorize, [:auth])
      resolve(&PartyInvitationResolver.accept_party_invitation/3)
    end

    @desc """
    User Declines Party Invitation
    """
    field :decline_party_invitation, :party_invitation_reponse do
      arg(:invitation_id, non_null(:string))
      middleware(Middleware.Authorize, [:auth])
      resolve(&PartyInvitationResolver.decline_party_invitation/3)
    end
  end
end
