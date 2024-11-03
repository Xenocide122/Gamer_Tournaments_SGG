defmodule Strident.Repo.Migrations.CreateTableTeamUserInvitationUsers do
  use Ecto.Migration

  def change do
    create table(:team_user_invitation_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false

      add :team_user_invitation_id,
          references(:team_user_invitations, on_delete: :nothing, type: :binary_id),
          null: false

      timestamps()
    end

    create index(:team_user_invitation_users, [:user_id])
    create index(:team_user_invitation_users, [:team_user_invitation_id])
  end
end
