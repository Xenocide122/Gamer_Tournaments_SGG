defmodule Strident.Repo.Local.Migrations.MakePartyInvitationUniquenessConstraintsAllowNulls do
  use Ecto.Migration

  def up do
    drop unique_index(:party_invitations, [:party_id, :email], name: :party_email_unique_index)

    create unique_index(:party_invitations, [:party_id, :email],
             name: :party_email_unique_index,
             where: "email IS NOT NULL"
           )

    create unique_index(:party_invitations, [:party_id, :user_id],
             name: :party_user_id_unique_index,
             where: "user_id IS NOT NULL"
           )
  end

  def down do
    drop unique_index(:party_invitations, [:party_id, :user_id], name: :party_user_id_unique_index)

    drop unique_index(:party_invitations, [:party_id, :email], name: :party_email_unique_index)
    create unique_index(:party_invitations, [:party_id, :email], name: :party_email_unique_index)
  end
end
