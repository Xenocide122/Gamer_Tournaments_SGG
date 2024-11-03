defmodule Strident.Repo.Migrations.AlterPartyMembersMoveSubstituteToField do
  use Ecto.Migration

  def change do
    alter table(:party_members) do
      add :substitute, :boolean, default: false
    end
  end
end
