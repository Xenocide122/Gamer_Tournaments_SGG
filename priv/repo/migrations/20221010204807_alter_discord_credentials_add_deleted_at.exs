defmodule Strident.Repo.Migrations.AlterDiscordCredentialsAddDeletedAt do
  use Ecto.Migration

  def change do
    alter table(:discord_credentials) do
      modify :email, :string, null: true
      add :deleted_at, :utc_datetime
    end

    drop unique_index(:discord_credentials, [:email], name: :discord_credentials_email_index)

    create unique_index(:discord_credentials, [:email],
             where: "deleted_at is null",
             name: :discord_credentials_non_deleted_email_unique_index
           )
  end
end
