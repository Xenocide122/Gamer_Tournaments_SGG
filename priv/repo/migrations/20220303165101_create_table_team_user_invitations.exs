defmodule Strident.Repo.Migrations.CreateTableTeamUserInvitations do
  use Ecto.Migration

  def change do
    create table(:team_user_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id), null: false
      add :email, :string
      add :invitation_token, :string
      add :status, :string

      timestamps()
    end
  end
end
