defmodule Strident.Repo.Migrations.AlterPartyMembersAddStatus do
  use Ecto.Migration

  def change do
    alter table(:party_members) do
      add :status, :string
    end

    execute """
    UPDATE party_members SET status='confirmed';
    """
  end
end
