defmodule Strident.Repo.Migrations.ModifyPlayerToCascadeDelete do
  use Ecto.Migration

  def up do
    drop(constraint(:players, "players_tournament_participant_id_fkey"))

    alter table(:players) do
      modify :tournament_participant_id,
             references(:tournament_participants, on_delete: :delete_all, type: :binary_id),
             null: false
    end
  end

  def down do
    drop(constraint(:players, "players_tournament_participant_id_fkey"))

    alter table(:players) do
      modify :tournament_participant_id,
             references(:tournament_participants, on_delete: :nothing, type: :binary_id),
             null: false
    end
  end
end
