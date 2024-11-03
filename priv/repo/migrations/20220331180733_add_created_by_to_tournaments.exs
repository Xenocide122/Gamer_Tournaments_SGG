defmodule Strident.Repo.Migrations.AddCreatedByToTournaments do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :created_by_user_id, references(:users, on_delete: :nothing, type: :binary_id),
        null: true
    end

    execute("""
    update tournaments set created_by_user_id = (select u.id from users as u
    join password_credentials as pc on pc.user_id = u.id where pc.email = 'james@grilla.gg')
    """)

    drop constraint(:tournaments, "tournaments_created_by_user_id_fkey")

    alter table(:tournaments) do
      modify :created_by_user_id, references(:users, on_delete: :nothing, type: :binary_id),
        null: false
    end
  end

  def down do
    alter table(:tournaments) do
      remove :created_by_user_id
    end
  end
end
