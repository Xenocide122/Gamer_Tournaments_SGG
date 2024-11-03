defmodule Strident.Repo.Migrations.CreatePartyInvitation do
  use Ecto.Migration

  def change do
    create table(:party_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :party_id, references(:parties, type: :binary_id, on_delete: :delete_all), null: false

      add :email, :string
      add :invitation_token, :string
      add :last_email_sent, :utc_datetime
      add :status, :string

      timestamps()
    end

    create unique_index(:party_invitations, [:party_id, :email], name: :party_email_unique_index)
  end
end
