defmodule Strident.Repo.Local.Migrations.ModifyValueOnTournamentParticipantRegistrationFields do
  use Ecto.Migration

  def change do
    rename table(:tournament_participant_registration_field),
      to: table(:tournament_participant_registration_fields)

    alter table(:tournament_participant_registration_fields) do
      modify :value, :text
    end
  end
end
