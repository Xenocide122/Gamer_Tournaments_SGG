defmodule Strident.Repo.Migrations.CreateTournamentRegistrationFields do
  use Ecto.Migration

  def change do
    create table(:tournament_registration_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tournament_id, references(:tournaments, type: :binary_id, on_delete: :delete_all),
        null: false

      add :field_name, :string, null: false
      add :field_type, :string, null: false

      timestamps()
    end
  end
end
