defmodule Strident.Repo.Migrations.AddUserIdPartyIdUniqueConstraintToPartyMembers do
  use Ecto.Migration

  def change do
    create unique_index(
             :party_members,
             [:party_id, :user_id],
             name: :party_members_user_party_unique_index
           )
  end
end
