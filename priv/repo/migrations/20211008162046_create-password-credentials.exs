defmodule Elixir.Strident.Repo.Migrations.CreatePasswordCredentials do
  use Ecto.Migration

  def up do
    create table(:password_credentials, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
    end

    create unique_index(:password_credentials, [:user_id])

    execute("""
    INSERT into password_credentials (user_id, email, hashed_password, confirmed_at)
    SELECT id, email, hashed_password, confirmed_at from users
    """)

    alter table(:users) do
      remove(:email)
      remove(:hashed_password)
      remove(:confirmed_at)
    end
  end

  def down do
    alter table(:users) do
      add :email, :citext, null: true
      add :hashed_password, :string, null: true
      add :confirmed_at, :naive_datetime
    end

    execute("""
    UPDATE users as u
    SET email = p.email, hashed_password = p.hashed_password, confirmed_at = p.confirmed_at
    FROM password_credentials AS p
    WHERE p.user_id = u.id
    """)

    drop table(:password_credentials)

    alter table(:users) do
      modify :email, :citext, null: false
      modify :hashed_password, :string, null: false
    end
  end
end
