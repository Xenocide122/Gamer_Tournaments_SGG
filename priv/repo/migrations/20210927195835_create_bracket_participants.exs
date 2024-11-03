defmodule Strident.Repo.Migrations.CreateBracketParticipants do
  use Ecto.Migration

  def change do
    create table(:bracket_participants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bracket_id, references(:brackets, on_delete: :nothing, type: :binary_id), null: false
      add :rank, :integer

      timestamps()
    end

    create index(:bracket_participants, [:bracket_id])
  end
end
