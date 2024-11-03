defmodule Strident.Repo.Local.Migrations.AddNullableUserIdToPartyInvitations do
  use Ecto.Migration

  def change do
    alter table(:party_invitations) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: true
    end
  end
end
