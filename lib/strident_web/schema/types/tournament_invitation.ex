defmodule StridentWeb.Schema.Types.TournamentInvitation do
  @moduledoc false
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :tournament_invitation do
    field(:id, non_null(:string))

    field :email, :string do
      resolve(fn _, _, resolution ->
        case resolution do
          %{
            context: %{current_user: %{email: same_email}},
            source: %{email: same_email}
          } ->
            {:ok, resolution.source.email}

          _ ->
            {:ok, nil}
        end
      end)
    end

    field(:last_email_sent, :datetime)

    field :invitation_token, :string do
      resolve(fn _, _, resolution ->
        case resolution do
          %{
            context: %{current_user: %{email: same_email}},
            source: %{email: same_email}
          } ->
            {:ok, resolution.source.invitation_token}

          _ ->
            {:ok, nil}
        end
      end)
    end

    field(:status, :tournament_invitation_status)

    field(:party, :party, resolve: dataloader(:data))
  end

  enum :tournament_invitation_status do
    value(:pending)
    value(:accepted)
    value(:rejected)
    value(:deleted)
  end
end
