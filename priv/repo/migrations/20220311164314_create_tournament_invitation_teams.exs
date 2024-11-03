defmodule Strident.Repo.Migrations.CreateTournamentInvitationTeams do
  use Ecto.Migration

  def change do
    create table(:tournament_invitation_teams, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_invitation_id,
          references(:tournament_invitations, on_delete: :nothing, type: :binary_id),
          null: false

      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:tournament_invitation_teams, [:team_id, :tournament_invitation_id],
             name: :link_tournament_invitation_team_unique_idx
           )
  end
end
