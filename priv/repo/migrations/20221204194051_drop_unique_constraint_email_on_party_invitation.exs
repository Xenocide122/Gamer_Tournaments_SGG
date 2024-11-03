defmodule Strident.Repo.Local.Migrations.DropUniqueConstraintEmailOnPartyInvitation do
  use Ecto.Migration

  def change do
    drop unique_index(:party_invitations, [:party_id, :email], name: :party_email_unique_index)
  end
end
