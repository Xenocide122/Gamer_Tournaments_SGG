defmodule Strident.Repo.Migrations.CreatePartyMembers do
  use Ecto.Migration

  def change do
    create table(:party_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :party_id, references(:parties, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:party_members, [:user_id, :party_id])
  end
end
