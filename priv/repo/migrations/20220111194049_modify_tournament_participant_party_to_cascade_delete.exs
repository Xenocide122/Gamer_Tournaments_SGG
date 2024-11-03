defmodule Strident.Repo.Migrations.ModifyTournamentParticipantPartyToCascadeDelete do
  use Ecto.Migration

  def up do
    drop(
      constraint(
        :tournament_participant_parties,
        "tournament_participant_parties_tournament_participant_id_fkey"
      )
    )

    alter table(:tournament_participant_parties) do
      modify :tournament_participant_id,
             references(:tournament_participants, on_delete: :delete_all, type: :binary_id),
             null: false
    end
  end

  def down do
    drop(
      constraint(
        :tournament_participant_parties,
        "tournament_participant_parties_tournament_participant_id_fkey"
      )
    )

    alter table(:tournament_participant_parties) do
      modify :tournament_participant_id,
             references(:tournament_participants, on_delete: :nothing, type: :binary_id),
             null: false
    end
  end
end
