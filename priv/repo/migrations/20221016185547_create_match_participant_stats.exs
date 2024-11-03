defmodule Strident.Repo.Migrations.CreateMatchParticipantStats do
  use Ecto.Migration

  def change do
    alter table(:match_participants) do
      add :stats, {:map, :decimal}
    end
  end
end
