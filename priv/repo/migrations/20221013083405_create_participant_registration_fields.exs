defmodule Strident.Repo.Migrations.CreateParticipantRegistrationFields do
  use Ecto.Migration

  def change do
    create table(:tournament_participant_registration_field, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_participant_id,
          references(:tournament_participants, type: :binary_id, on_delete: :delete_all),
          null: false

      add :name, :string
      add :type, :string
      add :value, :string

      timestamps()
    end
  end
end
