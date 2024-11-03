defmodule StridentWeb.Schema.Types.Party do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Strident.Accounts
  alias Strident.Parties.Party
  alias Strident.UrlGeneration
  alias StridentWeb.Schema.DataloaderUtils
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :party do
    field(:id, non_null(:string))
    field(:name, non_null(:string))

    field :email, :string do
      resolve(fn _, _, resolution ->
        with %{
               context: %{
                 loader: loader,
                 current_user: %{id: current_user_id, is_staff: is_staff}
               },
               source: source
             } <- resolution,
             true <- !!is_staff || is_member?(current_user_id, source, loader) do
          resolution.source.email
        else
          _ -> nil
        end
        |> then(&{:ok, &1})
      end)
    end

    field :logo_url, non_null(:string) do
      resolve(fn _, _ ->
        Accounts.return_default_avatar()
        |> UrlGeneration.absolute_path()
        |> then(&{:ok, &1})
      end)
    end

    field(:party_members, non_null(list_of(non_null(:party_member))), resolve: dataloader(:data))

    field(:party_invitations, non_null(list_of(non_null(:party_invitation))),
      resolve: dataloader(:data)
    )
  end

  object :party_member do
    field(:id, non_null(:string))
    field(:user, non_null(:user_profile), resolve: dataloader(:data))
    field(:substitute, non_null(:boolean))
    field(:type, non_null(:party_member_type))
    field(:status, non_null(:party_member_status))
  end

  enum :party_member_status do
    value(:confirmed)
    value(:dropped)
  end

  enum :party_member_type do
    value(:player)
    value(:captain)
    value(:coach)
    value(:manager)
  end

  object :party_invitation do
    field(:id, non_null(:string))
    field(:email, non_null(:string))
    field(:last_email_sent, non_null(:naive_datetime))
    field(:invitation_token, non_null(:string))
    field(:status, non_null(:party_invitation_status))
  end

  enum :party_invitation_status do
    value(:pending)
    value(:accepted)
    value(:rejected)
    value(:dropped)
  end

  defp is_member?(nil, _source, _loader), do: false

  defp is_member?(user_id, %Party{} = party, loader) do
    members = DataloaderUtils.get_via_loader(loader, :party_members, party)
    Enum.any?(members, &(&1.user_id == user_id))
  end
end
