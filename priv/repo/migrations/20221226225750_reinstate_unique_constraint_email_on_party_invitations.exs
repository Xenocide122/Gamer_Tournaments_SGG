defmodule Strident.Repo.Local.Migrations.ReinstateUniqueConstraintEmailOnPartyInvitations do
  use Ecto.Migration

  def change do
    create unique_index(:party_invitations, [:party_id, :email], name: :party_email_unique_index)
  end
end
