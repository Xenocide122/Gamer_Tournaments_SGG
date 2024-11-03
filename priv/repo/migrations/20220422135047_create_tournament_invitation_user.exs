defmodule Strident.Repo.Migrations.CreateTournamentInvitationUser do
  use Ecto.Migration

  def change do
    create table(:tournament_invitation_users, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_invitation_id,
          references(:tournament_invitations, on_delete: :nothing, type: :binary_id),
          null: true

      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: true

      timestamps()
    end

    create unique_index(:tournament_invitation_users, [:user_id, :tournament_invitation_id],
             name: :link_tournament_invitation_user_unique_idx
           )
  end
end
