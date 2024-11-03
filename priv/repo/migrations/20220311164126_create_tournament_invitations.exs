defmodule Strident.Repo.Migrations.CreateTournamentInvitations do
  use Ecto.Migration

  def change do
    create table(:tournament_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_id, references(:tournaments, type: :binary_id, on_delete: :delete_all),
        null: false

      add :email, :string
      add :invitation_token, :string
      add :status, :string

      timestamps()
    end

    create unique_index(:tournament_invitations, [:tournament_id, :email],
             name: :tournament_email_idx
           )
  end
end
