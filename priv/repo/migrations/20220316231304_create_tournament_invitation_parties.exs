defmodule Strident.Repo.Migrations.CreateTournamentInvitationParties do
  use Ecto.Migration

  def change do
    create table(:tournament_invitation_parties, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_invitation_id,
          references(:tournament_invitations, on_delete: :nothing, type: :binary_id)

      add :party_id, references(:parties, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create unique_index(:tournament_invitation_parties, [:party_id, :tournament_invitation_id],
             name: :link_tournament_invitation_party_unique_idx
           )
  end
end
