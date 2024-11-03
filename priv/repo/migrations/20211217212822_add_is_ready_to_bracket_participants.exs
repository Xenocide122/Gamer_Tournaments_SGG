defmodule Strident.Repo.Migrations.AddIsReadyToBracketParticipants do
  use Ecto.Migration

  def up do
    alter table(:bracket_participants) do
      add :is_ready, :boolean, null: true, default: false
    end

    execute("update bracket_participants set is_ready=false")

    alter table(:bracket_participants) do
      modify :is_ready, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:bracket_participants) do
      remove :is_ready
    end
  end
end
