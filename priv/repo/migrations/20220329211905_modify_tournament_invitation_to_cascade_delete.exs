defmodule Strident.Repo.Migrations.ModifyTournamentInvitationToCascadeDelete do
  use Ecto.Migration

  def up do
    drop(
      constraint(:tournament_invitations, "tournament_invitations_tournament_participant_id_fkey")
    )

    alter table(:tournament_invitations) do
      modify :tournament_participant_id,
             references(:tournament_participants, on_delete: :delete_all, type: :binary_id),
             null: false
    end

    drop(
      constraint(
        :tournament_invitation_parties,
        "tournament_invitation_parties_tournament_invitation_id_fkey"
      )
    )

    alter table(:tournament_invitation_parties) do
      modify :tournament_invitation_id,
             references(:tournament_invitations, on_delete: :delete_all, type: :binary_id),
             null: false
    end

    drop(
      constraint(
        :tournament_invitation_teams,
        "tournament_invitation_teams_tournament_invitation_id_fkey"
      )
    )

    alter table(:tournament_invitation_teams) do
      modify :tournament_invitation_id,
             references(:tournament_invitations, on_delete: :delete_all, type: :binary_id),
             null: false
    end
  end

  def down do
    drop(
      constraint(:tournament_invitations, "tournament_invitations_tournament_participant_id_fkey")
    )

    alter table(:tournament_invitations) do
      modify :tournament_participant_id,
             references(:tournament_participants, on_delete: :nothing, type: :binary_id),
             null: false
    end

    drop(
      constraint(
        :tournament_invitation_parties,
        "tournament_invitation_parties_tournament_invitation_id_fkey"
      )
    )

    alter table(:tournament_invitation_parties) do
      modify :tournament_invitation_id,
             references(:tournament_invitations, on_delete: :nothing, type: :binary_id),
             null: false
    end

    drop(
      constraint(
        :tournament_invitation_teams,
        "tournament_invitation_teams_tournament_invitation_id_fkey"
      )
    )

    alter table(:tournament_invitation_teams) do
      modify :tournament_invitation_id,
             references(:tournament_invitations, on_delete: :nothing, type: :binary_id),
             null: false
    end
  end
end
