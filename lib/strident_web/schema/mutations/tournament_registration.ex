defmodule StridentWeb.Schema.Mutations.TournamentRegistration do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias StridentWeb.Resolvers.TournamentRegistrationResolver
  alias StridentWeb.Schema.Middleware

  input_object :registration_opts_input do
    field(:participant_attrs, :participant_attrs_input)
    field(:amount, non_null(:money_input))
    field(:party_attrs, :party_attrs_input)
  end

  input_object :participant_attrs_input do
    field(:registration_fields, non_null(list_of(non_null(:registration_field_input))))
  end

  input_object :registration_field_input do
    field(:name, non_null(:string))
    field(:type, non_null(:registration_field_type))
    field(:value, non_null(:string))
  end

  input_object :party_attrs_input do
    field(:name, non_null(:string))
    field(:is_creator_manager, non_null(:boolean))
    field(:party_invitations, non_null(list_of(non_null(:party_invitation_input))))
  end

  input_object :party_invitation_input do
    field(:email, non_null(:string))
    field(:status, non_null(:party_invitation_status))
  end

  object :tournament_registration_reponse do
    field(:errors, list_of(non_null(:input_error)))
    field(:tournament_participant, :tournament_participant)
  end

  object :tournament_registration_mutations do
    @desc """
    Registers Participant to Tournament.
    """
    field :create_tournament_registration, :tournament_registration_reponse do
      arg(:tournament_id, non_null(:string))
      arg(:input, non_null(:registration_opts_input))
      arg(:invitation_id, :string)
      middleware(Middleware.Authorize, [:auth])
      resolve(&TournamentRegistrationResolver.create_tournament_registration/3)
    end
  end
end
