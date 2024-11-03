defmodule Strident.Repo.Migrations.AddReportedByUserIdToMatchReports do
  use Ecto.Migration

  def up do
    alter table(:match_reports) do
      add :reported_by_user_id, references(:users, on_delete: :nothing, type: :binary_id),
        null: true
    end

    execute("""
    update match_reports set reported_by_user_id = (select u.id from users as u
    join password_credentials as pc on pc.user_id = u.id where pc.email = 'james@grilla.gg')
    """)

    drop constraint(:match_reports, "match_reports_reported_by_user_id_fkey")

    alter table(:match_reports) do
      modify :reported_by_user_id, references(:users, on_delete: :nothing, type: :binary_id),
        null: false
    end
  end

  def down do
    alter table(:match_reports) do
      remove :reported_by_user_id
    end
  end
end
